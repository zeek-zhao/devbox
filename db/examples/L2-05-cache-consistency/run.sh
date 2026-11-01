#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l2_05_cache_consistency
KEY=db_l2_05_cache_consistency:item
mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"

sql_file="$(mktemp)"
python_file="$(mktemp)"
trap 'rm -f "$sql_file" "$python_file"' EXIT
cat >"$sql_file" <<SQL
USE $NS;
CREATE TABLE item (id integer PRIMARY KEY, value integer NOT NULL);
INSERT INTO item VALUES (1, 0);
SQL
mysql_file "$sql_file" >/dev/null
redis_cmd UNLINK "$KEY" >/dev/null

cat >"$python_file" <<'PY'
import threading

import pymysql
import redis

database = "db_l2_05_cache_consistency"
key = "db_l2_05_cache_consistency:item"
cache = redis.Redis(host="redis", password="devbox", decode_responses=True)
read_old = threading.Event()
writer_invalidated = threading.Event()
reader_filled = threading.Event()
failures = []
stale_cache_values = []


def db_connection():
    return pymysql.connect(
        host="mysql", user="root", password="devbox", database=database,
        autocommit=True,
    )


def reader():
    conn = db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT value FROM item WHERE id = 1")
            stale_value = cur.fetchone()[0]
        read_old.set()
        if not writer_invalidated.wait(timeout=5):
            raise RuntimeError("writer did not invalidate cache")
        cache.set(key, stale_value)
        stale_cache_values.append(int(cache.get(key)))
        reader_filled.set()
    except Exception as exc:
        failures.append(exc)
    finally:
        conn.close()


def writer():
    conn = db_connection()
    try:
        if not read_old.wait(timeout=5):
            raise RuntimeError("reader did not read old database value")
        with conn.cursor() as cur:
            cur.execute("UPDATE item SET value = 1 WHERE id = 1")
        cache.unlink(key)
        writer_invalidated.set()
        if not reader_filled.wait(timeout=5):
            raise RuntimeError("reader did not fill stale value")
        cache.unlink(key)
        with conn.cursor() as cur:
            cur.execute("SELECT value FROM item WHERE id = 1")
            current_value = cur.fetchone()[0]
        cache.set(key, current_value)
    except Exception as exc:
        failures.append(exc)
        writer_invalidated.set()
        reader_filled.set()
    finally:
        conn.close()


reader_thread = threading.Thread(target=reader)
writer_thread = threading.Thread(target=writer)
reader_thread.start()
writer_thread.start()
reader_thread.join(timeout=8)
writer_thread.join(timeout=8)
if reader_thread.is_alive() or writer_thread.is_alive():
    raise RuntimeError("cache consistency interleaving did not finish")
if failures:
    raise failures[0]

conn = db_connection()
try:
    with conn.cursor() as cur:
        cur.execute("SELECT value FROM item WHERE id = 1")
        db_value = cur.fetchone()[0]
finally:
    conn.close()
race_cache = stale_cache_values[0]
print(f"after race cache={race_cache} db={db_value}")
if race_cache == db_value:
    raise RuntimeError("the coordinated stale-fill race was not reproduced")

cache.unlink(key)
cache.set(key, db_value)
final_cache = int(cache.get(key))
print(f"after second delete and refill cache={final_cache} db={db_value}")
if final_cache != db_value:
    raise RuntimeError("cache did not converge to the database value")
cache.unlink(key)
PY
py_file "$python_file"
