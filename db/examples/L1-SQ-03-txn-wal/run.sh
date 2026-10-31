#!/usr/bin/env bash
# L1-SQ-03-txn-wal · 事务与 WAL
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

DB=/tmp/l1-sq-03-txn-wal.db
tb rm -f "$DB" "$DB-wal" "$DB-shm"
trap 'tb rm -f "$DB" "$DB-wal" "$DB-shm"' EXIT
tb python3 - "$DB" <<'PY'
import sqlite3
import sys

path = sys.argv[1]
first = sqlite3.connect(path, timeout=0.1)
second = sqlite3.connect(path, timeout=0.1)
try:
    mode = first.execute("PRAGMA journal_mode=WAL").fetchone()[0]
    first.execute("CREATE TABLE events (event_key TEXT PRIMARY KEY)")
    first.execute("INSERT INTO events VALUES ('kept')")
    first.commit()

    first.execute("BEGIN IMMEDIATE")
    first.execute("SAVEPOINT tentative")
    first.execute("INSERT INTO events VALUES ('rolled-back')")
    first.execute("ROLLBACK TO tentative")
    first.execute("RELEASE tentative")
    try:
        second.execute("BEGIN IMMEDIATE")
    except sqlite3.OperationalError as exc:
        if "locked" not in str(exc):
            raise
        print("concurrent_writer=locked")
    else:
        second.rollback()
        raise RuntimeError("second writer unexpectedly acquired the lock")
    first.commit()

    first.execute("BEGIN EXCLUSIVE")
    first.rollback()
    print(f"journal_mode={mode}")
    print("exclusive_begin=acquired")
    print(f"rows_after_savepoint={first.execute('SELECT COUNT(*) FROM events').fetchone()[0]}")
finally:
    first.close()
    second.close()
PY
