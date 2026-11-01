#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_pg_05_index_gin
psql_db "DROP DATABASE IF EXISTS $NS" >/dev/null
psql_db "CREATE DATABASE $NS" >/dev/null

sql_file="$(mktemp)"
trap 'rm -f "$sql_file"' EXIT
cat >"$sql_file" <<SQL
\set QUIET 1
\connect $NS
CREATE TABLE docs (
    id integer PRIMARY KEY,
    payload jsonb NOT NULL,
    tags text[] NOT NULL,
    state text NOT NULL,
    email text NOT NULL
);
INSERT INTO docs
SELECT n,
       jsonb_build_object('kind', CASE WHEN n = 997 THEN 'needle' ELSE 'hay' END),
       CASE WHEN n = 997 THEN ARRAY['rare'] ELSE ARRAY['common'] END,
       CASE WHEN n < 20 THEN 'active' ELSE 'archived' END,
       'USER' || n || '@EXAMPLE.TEST'
FROM generate_series(1, 1000) AS n;
CREATE INDEX docs_payload_gin ON docs USING gin (payload);
CREATE INDEX docs_tags_gin ON docs USING gin (tags);
CREATE INDEX docs_active_id_idx ON docs (id) WHERE state = 'active';
CREATE INDEX docs_email_lower_idx ON docs (lower(email));
ANALYZE docs;
SET enable_seqscan = off;
SET enable_indexscan = off;
SET enable_bitmapscan = on;
SELECT 'jsonb GIN';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id FROM docs WHERE payload @> '{"kind":"needle"}';
SELECT 'array GIN';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id FROM docs WHERE tags @> ARRAY['rare'];
SELECT 'partial index';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id FROM docs WHERE state = 'active' AND id < 5;
SELECT 'expression index';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id FROM docs WHERE lower(email) = 'user997@example.test';
SQL
psql_file "$sql_file" | awk '
  /^(jsonb GIN|array GIN|partial index|expression index)$/ { print; next }
  /Scan/ { sub(/ \(actual rows=.*/, ""); print }
'
