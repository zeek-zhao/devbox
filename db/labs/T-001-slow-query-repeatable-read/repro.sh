#!/usr/bin/env bash
# T-001-slow-query-repeatable-read 最小复现：一次性坐实两类高频排障现场——
#   ① 未加索引的等值查询：EXPLAIN type=ALL（全表扫）+ Handler 计数器读满全表；
#   ② REPEATABLE-READ 快照读：事务内第二次读看不到已提交的新行，新连接才看得到。
# 按 docs/72 §2 样板约定：复现成功 = 证据坐实 = 本脚本以退出码 1 结束，
# 证据行（EXPLAIN-SCAN / HANDLER-SCAN / SNAPSHOT / FRESH-READ）原样打到 stdout，
# 由调用方归一化后再断言。用后请 bash db/scripts/down.sh 收尾。
# 前置：devbox-db compose 栈在跑（db/scripts/up.sh）；口令 devbox 为教学固定值
# （ROADMAP KI-06 已声明，不算泄密）。用法：bash repro.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

C="${DB_MYSQL_CONTAINER:-devbox-db-mysql-1}"
mc() { docker exec "$C" env MYSQL_PWD=devbox mysql -uroot "$@"; }

docker ps --format '{{.Names}}' | grep -qx "$C" || {
  echo "repro: 容器 $C 未在运行（先 bash db/scripts/up.sh && bash db/scripts/wait-ready.sh；"
  echo "       注意 wait-ready 可能被 \$HOME/.devbox-db-compose 覆盖指向旧 worktree，见 WALKTHROUGH §4.0）" >&2
  exit 2
}

pass=0
fail=0

# 0) 独立命名空间，开始时清理，保证可重复运行
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
" >/dev/null 2>&1 || {
  echo "repro: 造数失败（mysql 不可用或权限异常）" >&2
  exit 2
}

# 1) 未加索引的等值查询：EXPLAIN type=ALL + Handler 全表读
exp="$(mc -N -B db_lab_t001 -e "FLUSH STATUS; SELECT val FROM big WHERE val = 19999; SHOW SESSION STATUS LIKE 'Handler_read%';" 2>&1)"
result="$(printf '%s\n' "$exp" | head -1)"
expl="$(mc -N -B db_lab_t001 -e "EXPLAIN SELECT val FROM big WHERE val = 19999;" 2>&1)"
etype="$(printf '%s\n' "$expl" | awk -F '\t' '{print $5; exit}')"
ekey="$(printf '%s\n' "$expl" | awk -F '\t' '{print $7; exit}')"
erows="$(printf '%s\n' "$expl" | awk -F '\t' '{print $10; exit}')"
rnd_next="$(printf '%s\n' "$exp" | awk -F '\t' '$1 == "Handler_read_rnd_next" {print $2; exit}')"
echo "EXPLAIN-SCAN: type=$etype key=$ekey rows=$erows (query val=19999 -> $result)"
echo "HANDLER-SCAN: read_rnd_next=$rnd_next"
if [ "$etype" = "ALL" ] && [ "$ekey" = "NULL" ] && [ "${erows:-0}" -ge 10000 ] &&
  [ "${rnd_next:-0}" -ge 10000 ] && [ "$result" = "19999" ]; then
  pass=$((pass + 1))
else
  echo "repro: 全表扫证据未坐实（type=$etype key=$ekey rows=$erows rnd_next=$rnd_next）" >&2
  fail=$((fail + 1))
fi

# 2) REPEATABLE-READ 快照读：A 会话首读 -> B 会话插入并提交 -> A 复读 -> 新连接读
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
mc -N -B db_lab_t001 -e "START TRANSACTION; INSERT INTO snap VALUES (2, 2); COMMIT;" || {
  echo "repro: B 会话插入失败" >&2
  fail=$((fail + 1))
}
wait "$ap"
arc=$?
sessA="$(cat "${TMPDIR:-/tmp}/devbox-db-T-001-sessA.log")"
printf '%s\n' "$sessA"
fresh="$(mc -N -B db_lab_t001 -e "SELECT CONCAT('fresh_read=', COUNT(*)) FROM snap;" 2>&1)"
echo "$fresh"
first="$(sed -nE 's/^first_read=([0-9]+)$/\1/p' <<<"$sessA")"
second="$(sed -nE 's/^second_read=([0-9]+)$/\1/p' <<<"$sessA")"
freshv="$(sed -nE 's/^fresh_read=([0-9]+)$/\1/p' <<<"$fresh")"
if [ "$arc" -eq 0 ] && [ "$first" = "1" ] && [ "$second" = "1" ] && [ "$freshv" = "2" ]; then
  pass=$((pass + 1))
else
  echo "repro: 快照读证据未坐实（arc=$arc first=$first second=$second fresh=$freshv）" >&2
  fail=$((fail + 1))
fi

# 复现成功 = 证据坐实 = 非零退出码（docs/72 §2，与 cpp/go 样板一致）
if [ "$fail" -eq 0 ] && [ "$pass" -eq 2 ]; then
  echo "REPRO-CONFIRMED: 2/2 证据坐实（按样板纪律退出码 1 = 现场在场）"
  exit 1
fi
echo "REPRO-BROKEN: $pass/2 证据坐实，$fail 项不符（环境异常，交维护者）" >&2
exit 3
