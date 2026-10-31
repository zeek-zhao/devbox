#!/usr/bin/env bash
# L1-SQ-08-vacuum-backup · VACUUM INTO 备份
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

DB=/tmp/l1-sq-08-vacuum-backup.db
BACKUP=/tmp/l1-sq-08-vacuum-backup-copy.db
SQL="$(mktemp)"
trap 'tb rm -f "$DB" "$BACKUP"; rm -f "$SQL"' EXIT
tb rm -f "$DB" "$BACKUP"
cat >"$SQL" <<'SQL'
.mode tabs
.headers off
PRAGMA page_size = 4096;
CREATE TABLE records (record_key TEXT PRIMARY KEY, value_text TEXT NOT NULL);
INSERT INTO records VALUES ('r-1','kept'), ('r-2','also-kept'), ('r-3','temporary');
DELETE FROM records WHERE record_key = 'r-3';
PRAGMA page_size;
VACUUM;
VACUUM INTO '/tmp/l1-sq-08-vacuum-backup-copy.db';
SQL
tb sqlite3 "$DB" <"$SQL"
tb sqlite3 "$BACKUP" <<'SQL'
.mode tabs
.headers off
PRAGMA integrity_check;
SELECT COUNT(*) FROM records ORDER BY record_key;
SQL
backup_bytes="$(tb wc -c "$BACKUP" | awk '{ print $1 }')"
if [ "$backup_bytes" -gt 0 ]; then
  echo "backup_nonempty=1"
else
  echo "backup_nonempty=0"
  exit 1
fi
