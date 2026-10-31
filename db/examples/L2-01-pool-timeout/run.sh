#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l2_01_pool_timeout
psql_db "DROP DATABASE IF EXISTS $NS" >/dev/null
psql_db "CREATE DATABASE $NS" >/dev/null

python_file="$(mktemp)"
trap 'rm -f "$python_file"' EXIT
cat >"$python_file" <<'PY'
from queue import Empty, Queue

import psycopg2

pool = Queue(maxsize=2)
connections = [
    psycopg2.connect(
        host="postgres", dbname="db_l2_01_pool_timeout",
        user="devbox", password="devbox",
    )
    for _ in range(2)
]
try:
    for connection in connections:
        pool.put_nowait(connection)
    held = [pool.get_nowait(), pool.get_nowait()]
    print("pool capacity=2; leases=2")
    try:
        pool.get(timeout=0.05)
    except Empty:
        print("third acquisition=timeout")
    pool.put_nowait(held.pop())
    reused = pool.get(timeout=0.05)
    with reused.cursor() as cur:
        cur.execute("SELECT 1")
        print(f"reused connection query={cur.fetchone()[0]}")
finally:
    for connection in connections:
        connection.close()
PY
py_file "$python_file"
