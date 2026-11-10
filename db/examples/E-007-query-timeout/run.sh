#!/usr/bin/env bash
# E-007-query-timeout · 慢查询超时：语句超时（3024）与锁等待超时（1205）
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_007_query_timeout

if ! tb mysql -h mysql -uroot -N -B -e 'SELECT 1' >/dev/null 2>&1; then
  bash "$DB_ROOT/scripts/up.sh" >/dev/null
  bash "$DB_ROOT/scripts/wait-ready.sh" >/dev/null
fi

cleanup() { mysql_db "DROP DATABASE IF EXISTS $NS" >/dev/null || true; }
trap cleanup EXIT

cleanup
mysql_db "CREATE DATABASE $NS CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
mysql_file "$HERE/schema.sql"

tb python3 - <<'PY'
import pymysql

ns = "db_e_E_007_query_timeout"


def connect(**kw):
    return pymysql.connect(host="mysql", user="root", password="devbox", **kw)


# ---- 1) 语句超时：读放大 2^44 行，1s 内跑不完 → 3024 ----
conn = connect(database=ns, autocommit=True)
cur = conn.cursor()
try:
    cur.execute(
        "SELECT /*+ MAX_EXECUTION_TIME(1000) */ SUM(a.x + b.x + c.x + d.x) "
        "FROM heat a, heat b, heat c, heat d"
    )
    raise SystemExit("expected the huge aggregate to time out")
except pymysql.MySQLError as e:
    print(f"stmt_timeout err={e.args[0]} class=timeout action=shrink")

# ---- 2) 锁等待超时：1205 只回滚语句，事务还活着 ----
holder = connect(database=ns, autocommit=False)
waiter = connect(database=ns, autocommit=False)
h, w = holder.cursor(), waiter.cursor()
h.execute("UPDATE accounts SET bal = bal - 1 WHERE id = 1")   # 不提交，持锁
w.execute("SET SESSION innodb_lock_wait_timeout = 2")
try:
    w.execute("UPDATE accounts SET bal = bal + 1 WHERE id = 1")
    raise SystemExit("expected the blocked update to time out")
except pymysql.MySQLError as e:
    print(f"lock_timeout err={e.args[0]} class=timeout retryable=yes")

# 1205 是语句级回滚：连接没有死，事务还开着
w.execute("SELECT bal FROM accounts WHERE id = 2")
print(f"victim_txn_alive id2={w.fetchone()[0]}")

# ---- 3) 处理：等持锁方结束 + 自己先结束当前事务，再重试 ----
holder.commit()
print("blocker_committed=yes")
waiter.rollback()
print("b_rolled_back=yes")

w.execute("UPDATE accounts SET bal = bal + 1 WHERE id = 1")
waiter.commit()
w.execute("SELECT id, bal FROM accounts ORDER BY id")
for rid, bal in w.fetchall():
    print(f"retry ok id={rid} bal={bal}")

conn.close()
holder.close()
waiter.close()
PY
