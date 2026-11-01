#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l2_06_batch_pagination
mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"

sql_file="$(mktemp)"
python_file="$(mktemp)"
trap 'rm -f "$sql_file" "$python_file"' EXIT
cat >"$sql_file" <<SQL
USE $NS;
CREATE TABLE events (
    id integer NOT NULL PRIMARY KEY,
    payload varchar(32) NOT NULL
);
INSERT INTO events
WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n + 1 FROM seq WHERE n < 1000
)
SELECT n, CONCAT('event-', n) FROM seq;
ANALYZE TABLE events;
SQL
mysql_file "$sql_file" >/dev/null

cat >"$python_file" <<'PY'
import re

import pymysql

conn = pymysql.connect(
    host="mysql", user="root", password="devbox",
    database="db_l2_06_batch_pagination",
)
queries = [
    ("deep OFFSET", "SELECT id FROM events ORDER BY id LIMIT 10 OFFSET 900"),
    ("keyset", "SELECT id FROM events WHERE id > 900 ORDER BY id LIMIT 10"),
]
try:
    with conn.cursor() as cur:
        for label, query in queries:
            cur.execute("EXPLAIN ANALYZE " + query)
            plan = cur.fetchone()[0]
            scan_rows = re.findall(
                r"scan[^\n]*actual time=[^\n]*?rows=(\d+)",
                plan,
                flags=re.IGNORECASE,
            )
            if not scan_rows:
                raise RuntimeError(f"could not find actual scan rows in plan: {plan}")
            print(f"{label} index scan actual rows={scan_rows[-1]}")
finally:
    conn.close()
PY
py_file "$python_file"
