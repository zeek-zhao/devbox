#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_pg_04_cte_recursive
psql_db "DROP DATABASE IF EXISTS $NS" >/dev/null
psql_db "CREATE DATABASE $NS" >/dev/null

sql_file="$(mktemp)"
trap 'rm -f "$sql_file"' EXIT
cat >"$sql_file" <<SQL
\set QUIET 1
\connect $NS
CREATE TABLE departments (
    id integer PRIMARY KEY,
    name text NOT NULL,
    parent_id integer REFERENCES departments(id)
);
INSERT INTO departments VALUES
    (1, 'Root', NULL), (2, 'Sales', 1), (3, 'Online', 2), (4, 'Support', 1);
WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, name::text AS path, 0 AS depth
    FROM departments
    WHERE parent_id IS NULL
    UNION ALL
    SELECT d.id, d.name, d.parent_id, t.path || '/' || d.name, t.depth + 1
    FROM departments AS d
    JOIN tree AS t ON d.parent_id = t.id
), materialized_tree AS MATERIALIZED (
    SELECT id, path, depth FROM tree
)
SELECT path, depth
FROM materialized_tree
ORDER BY path;
SQL
psql_file "$sql_file"
