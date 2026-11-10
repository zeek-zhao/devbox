#!/usr/bin/env bash
# E-002-constraint-catch · 约束违反的捕获与归因（唯一 / 检查 / 外键）
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_002_constraint_catch

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

ns = "db_e_E_002_constraint_catch"
conn = pymysql.connect(host="mysql", user="root", password="devbox",
                       database=ns, autocommit=True)
cur = conn.cursor()


def attempt(sql, args=()):
    try:
        cur.execute(sql, args)
        return None
    except pymysql.MySQLError as e:
        return e


# 唯一约束：重复 email
e = attempt("INSERT INTO users (email, age) VALUES (%s, %s)",
            ("a@devbox.local", 20))
print(f"dup_email err={e.args[0]} class=unique retryable=no")

# 检查约束：负年龄
e = attempt("INSERT INTO users (email, age) VALUES (%s, %s)",
            ("b@devbox.local", -1))
print(f"negative_age err={e.args[0]} class=check retryable=no")

# 外键约束：给不存在的用户下订单
e = attempt("INSERT INTO orders (user_id) VALUES (%s)", (999,))
print(f"orphan_order err={e.args[0]} class=foreign_key retryable=no")

# 合法订单先落一条，才能演示「删被引用的父行」
cur.execute("INSERT INTO orders (user_id) VALUES (%s)", (1,))
print("valid_order ok=1")
e = attempt("DELETE FROM users WHERE id = %s", (1,))
print(f"delete_parent err={e.args[0]} class=foreign_key retryable=no")

# 修正数据后正常落库
cur.execute("INSERT INTO users (email, age) VALUES (%s, %s)",
            ("b@devbox.local", 25))
print("insert_ok rows=1")
PY
