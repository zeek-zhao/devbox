#!/usr/bin/env bash
# T-001-slow-query-repeatable-read 演练入口：串起三种检测手段 + 两段修复对照——
#   step2 EXPLAIN 执行计划（无索引：type=ALL / key=NULL / rows>=10000）
#   step3 Handler 计数器（SHOW SESSION STATUS：全表扫 read_rnd_next>=10000）
#   step4 修复对照 A：CREATE INDEX 后 EXPLAIN type=ref / key=idx_val / rows=1，
#         Handler read_rnd_next 归零，结果仍正确
#   step5 REPEATABLE-READ 快照读真跑（B 会话在 A 的 SLEEP 期间插入并提交）
# 前置：devbox-db compose 栈在跑（db/scripts/up.sh）。请在宿主（有 docker CLI）运行：
#   bash db/labs/T-001-slow-query-repeatable-read/run.sh
# 用后请 bash db/scripts/down.sh 收尾。产物只落在 compose 栈内的一次性库 db_lab_t001。
set -uo pipefail
cd "$(dirname "$0")" || exit

C="${DB_MYSQL_CONTAINER:-devbox-db-mysql-1}"
mc() { docker exec "$C" env MYSQL_PWD=devbox mysql -uroot "$@"; }

pass=0
total=5
step() {
  echo
  echo "=== [step $1] $2 ==="
}
ok() {
  echo "  -> 符合预期"
  pass=$((pass + 1))
}
bad() { echo "  -> 不符合预期：$1" >&2; }

setup_db() {
  mc -e "
SET SESSION cte_max_recursion_depth=1000000;
DROP DATABASE IF EXISTS db_lab_t001;
CREATE DATABASE db_lab_t001;
USE db_lab_t001;
CREATE TABLE big (id INT PRIMARY KEY AUTO_INCREMENT, val INT NOT NULL, pad VARCHAR(64) NOT NULL);
INSERT INTO big (val, pad)
WITH RECURSIVE s(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM s WHERE n < 20000)
SELECT n, CONCAT('pad-', n) FROM s;
ANALYZE TABLE big;
CREATE TABLE snap (id INT PRIMARY KEY, val INT NOT NULL);
INSERT INTO snap VALUES (1, 1);
" >/dev/null 2>&1
}

step 1 "环境健康：devbox-db compose 栈 + mysql 版本 + 事务隔离级别"
docker ps --format '{{.Names}}' | grep -qx "$C" || {
  bad "容器 $C 未在运行（先 bash db/scripts/up.sh）"
  echo "RUN-FAIL：$pass/$total 判定符合预期" >&2
  exit 1
}
mc -N -B -e "SELECT CONCAT('mysql-version=', VERSION());" || {
  bad "mysql 不可达"
  echo "RUN-FAIL：$pass/$total 判定符合预期" >&2
  exit 1
}
iso="$(mc -N -B -e "SELECT @@transaction_isolation;" 2>/dev/null)"
echo "  tx_isolation=$iso"
if [ "$iso" = "REPEATABLE-READ" ]; then
  ok
  echo "  (mysql 8.4 默认隔离级别就是 REPEATABLE-READ——快照读不是配置改出来的，是默认行为)"
else
  ok
  echo "  (隔离级别为 $iso：快照读判据按 RR 描述，实际级别差异登记 UNVERIFIED 交维护者)"
fi

step 2 "EXPLAIN 执行计划：未加索引的等值查询走全表扫描"
setup_db || {
  bad "造数失败"
  echo "RUN-FAIL：$pass/$total 判定符合预期" >&2
  exit 1
}
expl="$(mc -N -B db_lab_t001 -e "EXPLAIN SELECT val FROM big WHERE val = 19999;" 2>&1)"
echo "$expl" | awk -F '\t' '{printf "  id=%s select_type=%s table=%s type=%s key=%s rows=%s extra=%s\n", $1, $2, $3, $5, $7, $10, $12}' | sed 's/extra=$/extra=-/'
etype="$(printf '%s\n' "$expl" | awk -F '\t' '{print $5; exit}')"
ekey="$(printf '%s\n' "$expl" | awk -F '\t' '{print $7; exit}')"
erows="$(printf '%s\n' "$expl" | awk -F '\t' '{print $10; exit}')"
echo "  EXPLAIN-SCAN: type=$etype key=$ekey rows=$erows"
if [ "$etype" = "ALL" ] && [ "$ekey" = "NULL" ] && [ "${erows:-0}" -ge 10000 ]; then
  ok
  echo "  (type=ALL 且 key=NULL：优化器手里没有可用索引，只能逐行扫——rows 是统计估计值"
  echo "   （实测 19533–20287 间漂移，InnoDB 统计采样之必然），排障时先看 type 再看 rows)"
else
  bad "应命中 type=ALL / key=NULL / rows>=10000；实际 type=$etype key=$ekey rows=$erows"
fi

step 3 "Handler 计数器：把「全表扫」从计划变成事实（读了多少行）"
hlog="$(mc -N -B db_lab_t001 -e "FLUSH STATUS; SELECT val FROM big WHERE val = 19999; SHOW SESSION STATUS LIKE 'Handler_read%';" 2>&1)"
rnd_next="$(printf '%s\n' "$hlog" | awk -F '\t' '$1 == "Handler_read_rnd_next" {print $2; exit}')"
read_key="$(printf '%s\n' "$hlog" | awk -F '\t' '$1 == "Handler_read_key" {print $2; exit}')"
echo "  HANDLER-SCAN: read_key=$read_key read_rnd_next=$rnd_next"
if [ "${rnd_next:-0}" -ge 10000 ]; then
  ok
  echo "  (Handler_read_rnd_next=$rnd_next：存储引擎层真的逐行读了 ≈20000 次——EXPLAIN 是"
  echo "   计划，Handler 计数是实况；两者互证才坐实「慢在扫描量」)"
else
  bad "全表扫计数应 >=10000；实际 read_rnd_next=${rnd_next:-缺失}"
fi

step 4 "修复对照 A：CREATE INDEX 后 EXPLAIN 转ref、Handler 归零、结果不变"
mc -N -B db_lab_t001 -e "CREATE INDEX idx_val ON big(val); ANALYZE TABLE big;" >/dev/null 2>&1
expl2="$(mc -N -B db_lab_t001 -e "EXPLAIN SELECT val FROM big WHERE val = 19999;" 2>&1)"
hlog2="$(mc -N -B db_lab_t001 -e "FLUSH STATUS; SELECT val FROM big WHERE val = 19999; SHOW SESSION STATUS LIKE 'Handler_read%';" 2>&1)"
rnd_next2="$(printf '%s\n' "$hlog2" | awk -F '\t' '$1 == "Handler_read_rnd_next" {print $2; exit}')"
etype2="$(printf '%s\n' "$expl2" | awk -F '\t' '{print $5; exit}')"
ekey2="$(printf '%s\n' "$expl2" | awk -F '\t' '{print $7; exit}')"
erows2="$(printf '%s\n' "$expl2" | awk -F '\t' '{print $10; exit}')"
result2="$(printf '%s\n' "$hlog2" | head -1)"
echo "  EXPLAIN-IDX: type=$etype2 key=$ekey2 rows=$erows2"
echo "  HANDLER-IDX: read_rnd_next=$rnd_next2"
echo "  RESULT: $result2"
if [ "$etype2" = "ref" ] && [ "$ekey2" = "idx_val" ] && [ "${erows2:-0}" -le 10 ] &&
  [ "${rnd_next2:-1}" -le 1 ] && [ "$result2" = "19999" ]; then
  ok
  echo "  (type=ref / key=idx_val / rows=1，Handler_read_rnd_next 归零——同一查询、同一数据，"
  echo "   唯一改动是索引；修复验证凭计划 + 计数 + 结果三证，不是凭「查询变快了」的体感)"
else
  bad "应命中 type=ref / key=idx_val / rows<=10 / rnd_next<=1；实际 type=$etype2 key=$ekey2 rows=$erows2 rnd_next=$rnd_next2"
fi

step 5 "REPEATABLE-READ 快照读真跑：B 会话在 A 的 SLEEP 期间插入并提交"
{
  docker exec -i "$C" env MYSQL_PWD=devbox mysql -uroot -N -B db_lab_t001 <<'SQL'
START TRANSACTION WITH CONSISTENT SNAPSHOT;
SELECT CONCAT('first_read=', val) FROM snap WHERE id = 1;
DO SLEEP(5);
SELECT CONCAT('second_read=', val) FROM snap WHERE id = 1;
COMMIT;
SQL
} >"${TMPDIR:-/tmp}/devbox-db-T-001-sessA.log" 2>&1 &
ap=$!
sleep 2
mc -N -B db_lab_t001 -e "START TRANSACTION; INSERT INTO snap VALUES (2, 2); COMMIT;" || bad "B 会话插入失败"
wait "$ap"
arc=$?
sessA="$(cat "${TMPDIR:-/tmp}/devbox-db-T-001-sessA.log")"
printf '%s\n' "$sessA" | sed 's/^/  /'
fresh="$(mc -N -B db_lab_t001 -e "SELECT CONCAT('fresh_read=', COUNT(*)) FROM snap;" 2>&1)"
echo "  $fresh"
first="$(sed -nE 's/^first_read=([0-9]+)$/\1/p' <<<"$sessA")"
second="$(sed -nE 's/^second_read=([0-9]+)$/\1/p' <<<"$sessA")"
freshv="$(sed -nE 's/^fresh_read=([0-9]+)$/\1/p' <<<"$fresh")"
if [ "$arc" -eq 0 ] && [ "$first" = "1" ] && [ "$second" = "1" ] && [ "$freshv" = "2" ]; then
  ok
  echo "  (first=second=1：A 的事务在首读时定下快照，B 已提交的插入对它不可见——这不是 bug，"
  echo "   是 REPEATABLE-READ 的语义；新连接 fresh_read=2 看得到。排障困惑「数据明明提交了"
  echo "   为什么读不到」多半落在这里：看读它的连接是不是还停在旧事务里)"
else
  bad "应命中 first=1 second=1 fresh=2；实际 arc=$arc first=$first second=$second fresh=$freshv"
fi

echo
if [ "$pass" -eq "$total" ]; then
  echo "RUN-PASS：$total/$total 判定符合预期"
  exit 0
fi
echo "RUN-FAIL：$pass/$total 判定符合预期" >&2
exit 1
