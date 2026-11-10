#!/usr/bin/env bash
# E-013-backup-corrupt-detect · 备份完整性：截断检测、恢复失败归因与完好副本兜底
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_013_backup_corrupt_detect

if ! tb mysql -h mysql -uroot -N -B -e 'SELECT 1' >/dev/null 2>&1; then
  bash "$DB_ROOT/scripts/up.sh" >/dev/null
  bash "$DB_ROOT/scripts/wait-ready.sh" >/dev/null
fi

cleanup() {
  mysql_db "DROP DATABASE IF EXISTS $NS" >/dev/null || true
  mysql_db "DROP DATABASE IF EXISTS db_e_E_013_restore" >/dev/null || true
}
trap cleanup EXIT

cleanup
mysql_db "CREATE DATABASE $NS CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
mysql_file "$HERE/schema.sql"

# 生成备份与「运输途中被截断」的坏副本（都用固定比例截断，保证可复现）
tb sh -c "mysqldump -h mysql -uroot '$NS' > /tmp/e013_good.sql" >/dev/null 2>&1
# 固定偏移截断（落在 INSERT 数据行中间）：产物字节稳定，坏点可复现
tb sh -c 'head -c 1450 /tmp/e013_good.sql > /tmp/e013_bad.sql' >/dev/null

tb python3 - <<'PY'
import pymysql

RESTORE = "db_e_E_013_restore"


def connect(**kw):
    return pymysql.connect(host="mysql", user="root", password="devbox", **kw)


def statements(path):
    # mysqldump 的语句以 '; ' 结尾逐条切分；本例数据无内嵌分号
    return [s.strip() for s in open(path, encoding="utf-8").read().split(";\n") if s.strip()]


def restore(path):
    """把 dump 逐句重放进全新库；返回 (完成语句数, 错误)。"""
    root = connect(autocommit=True)
    cur = root.cursor()
    cur.execute(f"DROP DATABASE IF EXISTS {RESTORE}")
    cur.execute(f"CREATE DATABASE {RESTORE} CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci")
    cur.execute(f"USE {RESTORE}")
    done, err = 0, None
    for s in statements(path):
        try:
            cur.execute(s)
        except pymysql.MySQLError as e:
            err = e
            break
        done += 1
    root.close()
    return done, err


# ---- 1) 廉价完整性检查：mysqldump 结尾的 Dump completed 标记 ----
good_tail = "Dump completed" in open("/tmp/e013_good.sql", encoding="utf-8").read()[-100:]
bad_tail = "Dump completed" in open("/tmp/e013_bad.sql", encoding="utf-8").read()[-100:]
print(f"tail_marker good={'yes' if good_tail else 'no'} bad={'yes' if bad_tail else 'no'}")

# ---- 2) 恢复坏副本：中途断句，1064 语法错误——「备份坏了」的实锤 ----
done, err = restore("/tmp/e013_bad.sql")
print(f"corrupt_restore stmts_done={done} err={err.args[0] if err else 'none'} detected={'yes' if err else 'no'}")

# ---- 3) 恢复完好副本 + 指纹验收：CHECKSUM TABLE 必须与源表一致 ----
root = connect(database=RESTORE, autocommit=True)
cur = root.cursor()
restore("/tmp/e013_good.sql")
cur.execute(f"CHECKSUM TABLE {RESTORE}.orders")
restore_sum = cur.fetchone()[1]
cur.execute(f"CHECKSUM TABLE db_e_E_013_backup_corrupt_detect.orders")
source_sum = cur.fetchone()[1]
cur.execute(f"SELECT COUNT(*) FROM {RESTORE}.orders")
rows = cur.fetchone()[0]
print(f"good_restore rows={rows} checksum_match={'yes' if restore_sum == source_sum else 'no'}")
root.close()
PY
