#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_pg_08_schema_grant
ROLE=db_l1_pg_08_schema_grant_reader
psql_db "DROP DATABASE IF EXISTS $NS" >/dev/null
psql_db "DROP ROLE IF EXISTS $ROLE" >/dev/null
psql_db "CREATE DATABASE $NS" >/dev/null
psql_db "CREATE ROLE $ROLE" >/dev/null

sql_file="$(mktemp)"
python_file="$(mktemp)"
trap 'rm -f "$sql_file" "$python_file"' EXIT
cat >"$sql_file" <<SQL
\set QUIET 1
\connect $NS
CREATE SCHEMA app;
CREATE TABLE app.secret_data (value text NOT NULL);
INSERT INTO app.secret_data VALUES ('classified');
GRANT USAGE ON SCHEMA app TO $ROLE;
SQL
psql_file "$sql_file"

cat >"$python_file" <<'PY'
import psycopg2
from psycopg2 import errors

conn = psycopg2.connect(
    host="postgres", dbname="db_l1_pg_08_schema_grant",
    user="devbox", password="devbox",
)
try:
    with conn.cursor() as cur:
        cur.execute("SET search_path TO app")
        cur.execute("SHOW search_path")
        print(f"search_path={cur.fetchone()[0]}")
        cur.execute("SET ROLE db_l1_pg_08_schema_grant_reader")
        try:
            cur.execute("SELECT value FROM app.secret_data")
        except errors.InsufficientPrivilege:
            conn.rollback()
            print("cross-schema table access=denied")
finally:
    conn.close()
PY
py_file "$python_file"
