#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_pg_01_types_jsonb
psql_db "DROP DATABASE IF EXISTS $NS" >/dev/null
psql_db "CREATE DATABASE $NS" >/dev/null

sql_file="$(mktemp)"
trap 'rm -f "$sql_file"' EXIT
cat >"$sql_file" <<SQL
\set QUIET 1
\connect $NS
CREATE TABLE documents (
    id integer PRIMARY KEY,
    body_json json NOT NULL,
    body_jsonb jsonb NOT NULL,
    labels text[] NOT NULL,
    span int4range NOT NULL
);
INSERT INTO documents VALUES
    (1, '{"profile":{"name":"Ada"}}', '{"profile":{"name":"Ada"}}',
     ARRAY['sql','json'], '[1,5)');
SELECT body_jsonb #>> '{profile,name}' AS jsonb_path
FROM documents
WHERE id = 1;
SELECT label
FROM documents CROSS JOIN LATERAL unnest(labels) AS label
ORDER BY label;
SELECT span::text FROM documents ORDER BY id;
SQL
psql_file "$sql_file"
