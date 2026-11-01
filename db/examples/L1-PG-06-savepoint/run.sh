#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_pg_06_savepoint
psql_db "DROP DATABASE IF EXISTS $NS" >/dev/null
psql_db "CREATE DATABASE $NS" >/dev/null

python_file="$(mktemp)"
trap 'rm -f "$python_file"' EXIT
cat >"$python_file" <<'PY'
import psycopg2
from psycopg2 import errors

conn = psycopg2.connect(
    host="postgres", dbname="db_l1_pg_06_savepoint",
    user="devbox", password="devbox",
)
try:
    with conn.cursor() as cur:
        cur.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ")
        cur.execute("SHOW transaction_isolation")
        print(f"isolation={cur.fetchone()[0]}")
        cur.execute("CREATE TABLE entries (id integer PRIMARY KEY)")
        cur.execute("INSERT INTO entries VALUES (1)")
        cur.execute("SAVEPOINT before_duplicate")
        try:
            cur.execute("INSERT INTO entries VALUES (1)")
        except errors.UniqueViolation as exc:
            print(f"duplicate SQLSTATE={exc.pgcode}")
        try:
            cur.execute("SELECT count(*) FROM entries")
        except errors.InFailedSqlTransaction as exc:
            print(f"transaction state SQLSTATE={exc.pgcode}")
        cur.execute("ROLLBACK TO SAVEPOINT before_duplicate")
        cur.execute("SELECT count(*) FROM entries")
        print(f"rows after rollback to savepoint={cur.fetchone()[0]}")
    conn.commit()
finally:
    conn.close()
PY
py_file "$python_file"
