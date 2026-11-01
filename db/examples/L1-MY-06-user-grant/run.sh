#!/usr/bin/env bash
# L1-MY-06-user-grant · 用户与权限
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_my_06_user_grant
USER_NAME=u_l1_my_06_app
mysql_db "DROP USER IF EXISTS '$USER_NAME'@'%'; DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"
cleanup() { mysql_db "DROP USER IF EXISTS '$USER_NAME'@'%';" >/dev/null; }
trap cleanup EXIT

SQL="$(mktemp)"
trap 'rm -f "$SQL"; cleanup' EXIT
cat >"$SQL" <<'SQL'
USE db_l1_my_06_user_grant;
CREATE TABLE records (record_key VARCHAR(16) PRIMARY KEY, value_text VARCHAR(32) NOT NULL);
INSERT INTO records VALUES ('alpha','readable');
CREATE USER 'u_l1_my_06_app'@'%' IDENTIFIED BY 'sample-pass';
GRANT SELECT ON db_l1_my_06_user_grant.* TO 'u_l1_my_06_app'@'%';
GRANT INSERT ON db_l1_my_06_user_grant.records TO 'u_l1_my_06_app'@'%';
SHOW GRANTS FOR 'u_l1_my_06_app'@'%';
SQL
mysql_file "$SQL"
tb python3 - <<'PY'
import pymysql

conn = pymysql.connect(host="mysql", user="u_l1_my_06_app",
                       password="sample-pass", database="db_l1_my_06_user_grant")
try:
    with conn.cursor() as cur:
        cur.execute("SELECT value_text FROM records WHERE record_key = 'alpha'")
        print(f"select={cur.fetchone()[0]}")
        try:
            cur.execute("UPDATE records SET value_text = 'denied' WHERE record_key = 'alpha'")
        except pymysql.err.OperationalError as exc:
            print(f"update_denied={exc.args[0]}")
finally:
    conn.close()
PY
