#!/usr/bin/env bash
# L1-SQ-05-view-trigger · 视图与触发器
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

DB=/tmp/l1-sq-05-view-trigger.db
SQL="$(mktemp)"
trap 'tb rm -f "$DB"; rm -f "$SQL"' EXIT
tb rm -f "$DB"
cat >"$SQL" <<'SQL'
.mode tabs
.headers off
CREATE TABLE tasks (task_key TEXT PRIMARY KEY, state TEXT NOT NULL);
CREATE TABLE audit (action TEXT NOT NULL, task_key TEXT NOT NULL);
CREATE VIEW open_tasks AS SELECT task_key FROM tasks WHERE state = 'open';
CREATE TRIGGER add_open_task INSTEAD OF INSERT ON open_tasks
BEGIN
  INSERT INTO tasks VALUES (NEW.task_key, 'open');
  INSERT INTO audit VALUES ('insert', NEW.task_key);
END;
INSERT INTO open_tasks VALUES ('task-a'), ('task-b');
SELECT 'audit_rows', COUNT(*) FROM audit;
SELECT task_key, state FROM tasks ORDER BY task_key;
WITH RECURSIVE levels(n, path) AS (
  SELECT 1, 'root'
  UNION ALL
  SELECT n + 1, path || '/' || (n + 1) FROM levels WHERE n < 3
)
SELECT path FROM levels ORDER BY n;
SQL
tb sqlite3 "$DB" <"$SQL"
