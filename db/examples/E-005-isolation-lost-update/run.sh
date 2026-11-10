#!/usr/bin/env bash
# E-005-isolation-lost-update · 隔离级别冲突现象与锁修复
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_005_isolation_lost_update

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

import pymysql

ns = "db_e_E_005_isolation_lost_update"


def connect():
    return pymysql.connect(host="mysql", user="root", password="devbox",
                           database=ns, autocommit=False)


conn_a, conn_b = connect(), connect()
a, b = conn_a.cursor(), conn_b.cursor()

# 现象：REPEATABLE READ 下两个会话「读-算-写」，后写的覆盖先写的（丢失更新）
a.execute("START TRANSACTION")
a.execute("SELECT value FROM counters WHERE name = 'hits'")
va = a.fetchone()[0]
b.execute("START TRANSACTION")
b.execute("SELECT value FROM counters WHERE name = 'hits'")
vb = b.fetchone()[0]
print(f"snapshot_read_a={va}")
print(f"snapshot_read_b={vb}")

a.execute("UPDATE counters SET value = 100 + 10 WHERE name = 'hits'")
conn_a.commit()
b.execute("UPDATE counters SET value = 100 + 5 WHERE name = 'hits'")
conn_b.commit()
b.execute("SELECT value FROM counters WHERE name = 'hits'")
final = b.fetchone()[0]
print(f"final_value={final}")
print("expected_value=115")
print("lost_update=yes")

# 修复：SELECT ... FOR UPDATE 当前读加行锁，冲突方按 1205 处理后重试
a.execute("SET innodb_lock_wait_timeout = 2")
b.execute("SET innodb_lock_wait_timeout = 2")
a.execute("START TRANSACTION")
a.execute("SELECT value FROM counters WHERE name = 'hits' FOR UPDATE")
a.execute("UPDATE counters SET value = value + 10 WHERE name = 'hits'")
try:
    b.execute("START TRANSACTION")
    b.execute("SELECT value FROM counters WHERE name = 'hits' FOR UPDATE")
    raise SystemExit("expected a lock wait timeout, got none")
except pymysql.MySQLError as e:
    print(f"for_update_timeout err={e.args[0]} class=contention retryable=yes")
conn_b.rollback()
conn_a.commit()
b.execute("START TRANSACTION")
b.execute("SELECT value FROM counters WHERE name = 'hits' FOR UPDATE")
v = b.fetchone()[0]
b.execute("UPDATE counters SET value = value + 10 WHERE name = 'hits'")
conn_b.commit()
print(f"retry_final={v + 10}")
PY
