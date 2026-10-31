#!/usr/bin/env bash
# L4-09-soft-delete · 软删除与历史追溯
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"
NS=db_l4_09_soft_delete
script="$(mktemp)"
trap 'rm -f "$script"' EXIT

mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"
cat >"$script" <<'PY'
import pymysql

db = pymysql.connect(host="mysql", user="root", password="devbox",
                     database="db_l4_09_soft_delete", autocommit=True)
with db.cursor() as cur:
    cur.execute("CREATE TABLE legacy_users (email VARCHAR(80) NOT NULL UNIQUE, "
                "deleted_at DATETIME NULL)")
    cur.execute("INSERT INTO legacy_users VALUES ('a@example.test',NULL)")
    cur.execute("UPDATE legacy_users SET deleted_at='2026-01-01 00:00:00' "
                "WHERE email='a@example.test'")
    try:
        cur.execute("INSERT INTO legacy_users VALUES ('a@example.test',NULL)")
    except pymysql.err.IntegrityError as exc:
        if exc.args[0] != 1062:
            raise
        print("legacy unique(email): reuse=BLOCKED (1062)")
    cur.execute(
        "CREATE TABLE users (user_key INT PRIMARY KEY AUTO_INCREMENT, "
        "email VARCHAR(80) NOT NULL, deleted_at DATETIME NULL, "
        "active_email VARCHAR(80) GENERATED ALWAYS AS "
        "(IF(deleted_at IS NULL,email,NULL)) STORED, UNIQUE(active_email))")
    cur.execute("INSERT INTO users (email,deleted_at) "
                "VALUES ('a@example.test','2026-01-01 00:00:00')")
    cur.execute("INSERT INTO users (email,deleted_at) VALUES ('a@example.test',NULL)")
    cur.execute("SELECT COUNT(*) FROM users WHERE email='a@example.test'")
    print(f"generated active key: reuse=OK history_rows={cur.fetchone()[0]}")
    cur.execute("SELECT IF(deleted_at IS NULL,'active','deleted') FROM users "
                "WHERE email='a@example.test' ORDER BY deleted_at IS NULL,deleted_at")
    print("history query: " + ",".join(row[0] for row in cur.fetchall()))
db.close()
PY
py_file "$script"
