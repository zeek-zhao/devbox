#!/usr/bin/env bash
# L1-SQ-07-json1 · json1 扩展
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

DB=/tmp/l1-sq-07-json1.db
SQL="$(mktemp)"
trap 'tb rm -f "$DB"; rm -f "$SQL"' EXIT
tb rm -f "$DB"
cat >"$SQL" <<'SQL'
.mode tabs
.headers off
CREATE TABLE documents (doc_key TEXT PRIMARY KEY, body TEXT NOT NULL);
INSERT INTO documents VALUES ('d-1', '{"name":"Mika","score":7,"active":true}');
SELECT key, value, type FROM documents, json_each(body)
WHERE doc_key = 'd-1'
ORDER BY key;
SELECT json_extract(body, '$.score'),
       json_set(body, '$.score', 8) ->> '$.score',
       body -> '$.name',
       body ->> '$.name'
FROM documents WHERE doc_key = 'd-1';
SQL
tb sqlite3 "$DB" <"$SQL"
