#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l2_02_slow_query
psql_db "DROP DATABASE IF EXISTS $NS" >/dev/null
psql_db "CREATE DATABASE $NS" >/dev/null

python_file="$(mktemp)"
trap 'rm -f "$python_file"' EXIT
cat >"$python_file" <<'PY'
import threading
import time

import psycopg2

marker = "l2_02_slow_query_marker"
started = threading.Event()
errors = []


def execute_slow_query():
    try:
        conn = psycopg2.connect(
            host="postgres", dbname="db_l2_02_slow_query",
            user="devbox", password="devbox",
        )
        try:
            with conn.cursor() as cur:
                started.set()
                cur.execute("SELECT pg_sleep(2), %s", (marker,))
        finally:
            conn.close()
    except Exception as exc:
        errors.append(exc)


worker = threading.Thread(target=execute_slow_query)
worker.start()
if not started.wait(timeout=3):
    raise RuntimeError("slow-query worker did not start")

reader = psycopg2.connect(
    host="postgres", dbname="db_l2_02_slow_query",
    user="devbox", password="devbox",
)
found = False
try:
    deadline = time.monotonic() + 3
    with reader.cursor() as cur:
        while time.monotonic() < deadline:
            cur.execute(
                "SELECT state FROM pg_stat_activity WHERE datname = %s "
                "AND query LIKE %s AND pid <> pg_backend_pid()",
                ("db_l2_02_slow_query", f"%{marker}%"),
            )
            row = cur.fetchone()
            if row and row[0] == "active":
                found = True
                break
            time.sleep(0.01)
finally:
    reader.close()
worker.join(timeout=4)
if worker.is_alive():
    raise RuntimeError("slow-query worker did not finish")
if errors:
    raise errors[0]
if not found:
    raise RuntimeError("slow query was not visible in pg_stat_activity")
print("active query captured from pg_stat_activity")
PY
py_file "$python_file"
