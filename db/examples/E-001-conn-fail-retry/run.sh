#!/usr/bin/env bash
# E-001-conn-fail-retry · 连接失败的处理与重试
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_001_conn_fail_retry

# 自包含：栈没起来就先起（up.sh / wait-ready.sh 都幂等）
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
import time

import pymysql

ns = "db_e_E_001_conn_fail_retry"


def classify(code):
    if code in (2003, 2002, 2006, 2013):
        return "environment", "yes"
    if code in (1044, 1045, 1698):
        return "credentials", "no"
    return "unknown", "no"


def try_connect(**kw):
    try:
        return pymysql.connect(**kw), None
    except pymysql.MySQLError as e:
        return None, e


conn, _ = try_connect(host="mysql", user="root", password="devbox", database=ns)
cur = conn.cursor()

# 1) 连不上的端口：环境类错误，按预算重试
for attempt in (1, 2, 3):
    _, err = try_connect(host="127.0.0.1", port=1, user="root",
                         password="devbox", connect_timeout=2)
    code = err.args[0]
    cat, retryable = classify(code)
    print(f"attempt={attempt} err={code} class={cat} retryable={retryable}")
    cur.execute("INSERT INTO conn_log (err_code) VALUES (%s)", (code,))
    conn.commit()
    time.sleep(0.1)
print("retry_budget_exhausted=yes")

# 2) 错误口令：凭证类错误，重试无意义
_, err = try_connect(host="mysql", user="root", password="wrong-pass")
code = err.args[0]
cat, retryable = classify(code)
print(f"bad_password err={code} class={cat} retryable={retryable}")

# 3) 正确连接
cur.execute("INSERT INTO conn_log (err_code) VALUES (NULL)")
conn.commit()
cur.execute("SELECT COUNT(*) FROM conn_log")
rows = cur.fetchone()[0]
cur.execute("SELECT COUNT(*) FROM conn_log WHERE err_code IS NULL")
ok = cur.fetchone()[0]
print(f"connect_ok=1")
print(f"log_rows={rows}")
print(f"log_success={ok}")
PY
