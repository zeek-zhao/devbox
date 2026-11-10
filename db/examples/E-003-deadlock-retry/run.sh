#!/usr/bin/env bash
# E-003-deadlock-retry · 死锁检测、受害者归因与重试
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_003_deadlock_retry

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
import os
import threading
import time

import pymysql

ns = "db_e_E_003_deadlock_retry"


def connect():
    return pymysql.connect(host="mysql", user="root", password="devbox",
                           database=ns, autocommit=False)


conn_a, conn_b = connect(), connect()
a, b = conn_a.cursor(), conn_b.cursor()

# 事务 A 先锁两行（权重更重），事务 B 锁一行，两者再互要对方的锁
a.execute("START TRANSACTION")
a.execute("UPDATE accounts SET balance = balance - 10 WHERE id = 1")
a.execute("UPDATE accounts SET balance = balance - 5 WHERE id = 3")
b.execute("START TRANSACTION")
b.execute("UPDATE accounts SET balance = balance - 20 WHERE id = 2")

a_res = {}


def a_step2():
    try:
        a.execute("UPDATE accounts SET balance = balance - 10 WHERE id = 2")
        a_res["err"] = None
    except pymysql.MySQLError as e:
        a_res["err"] = e


t = threading.Thread(target=a_step2)
t.start()
time.sleep(0.5)

b_err = None
try:
    b.execute("UPDATE accounts SET balance = balance - 5 WHERE id = 1")
except pymysql.MySQLError as e:
    b_err = e
t.join()

victim = None
if a_res.get("err") is not None and a_res["err"].args[0] == 1213:
    victim = "a"
if b_err is not None and b_err.args[0] == 1213:
    victim = "b"
if victim is None:
    raise SystemExit("expected a deadlock, got none")
print(f"deadlock err=1213 victim={victim} retryable=yes")

if victim == "b":
    conn_b.rollback()
    conn_a.commit()
    print("a_committed=yes")
    retry = b
    retry_conn = conn_b
else:
    conn_a.rollback()
    conn_b.commit()
    print("b_committed=yes")
    retry = a
    retry_conn = conn_a

# 受害者整体回滚后重试同一笔业务
retry.execute("START TRANSACTION")
retry.execute("UPDATE accounts SET balance = balance - 20 WHERE id = 2")
retry.execute("UPDATE accounts SET balance = balance - 5 WHERE id = 1")
retry_conn.commit()
print("retry attempt=2 ok=yes")

check = conn_a.cursor()
check.execute("SELECT id, balance FROM accounts ORDER BY id")
for row in check.fetchall():
    print(f"final id={row[0]} balance={row[1]}")
PY
