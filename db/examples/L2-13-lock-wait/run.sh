#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh
db=db_l2_13_lock_wait
mysql_db "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db; CREATE TABLE $db.lock_rows (id INT PRIMARY KEY, value INT NOT NULL) ENGINE=InnoDB; INSERT INTO $db.lock_rows VALUES (1,0),(2,0);"
tb python3 - <<'PY'
import threading
import time
import pymysql

def connect():
    return pymysql.connect(host="mysql", user="root", password="devbox", database="db_l2_13_lock_wait", autocommit=False)

blocker = connect()
blocker.cursor().execute("SELECT value FROM lock_rows WHERE id=1 FOR UPDATE")
blocker_id = blocker.thread_id()
ready = threading.Event()
errors = []
waiter_ids = []

def wait_on_row():
    conn = connect()
    try:
        cur = conn.cursor()
        cur.execute("SET innodb_lock_wait_timeout=15")
        cur.execute("UPDATE lock_rows SET value=value+1 WHERE id=2")
        waiter_ids.append(conn.thread_id())
        ready.set()
        cur.execute("UPDATE lock_rows SET value=value+1 WHERE id=1")
        conn.commit()
    except Exception as exc:
        errors.append(exc)
        conn.rollback()
    finally:
        conn.close()

thread = threading.Thread(target=wait_on_row)
thread.start()
assert ready.wait(5)
observer = connect()
chain = None
deadline = time.monotonic() + 8
while time.monotonic() < deadline:
    with observer.cursor() as cur:
        cur.execute("""SELECT req.PROCESSLIST_ID, blk.PROCESSLIST_ID
                       FROM performance_schema.data_lock_waits w
                       JOIN performance_schema.threads req ON req.THREAD_ID=w.REQUESTING_THREAD_ID
                       JOIN performance_schema.threads blk ON blk.THREAD_ID=w.BLOCKING_THREAD_ID""")
        chain = cur.fetchone()
        if chain:
            break
    time.sleep(0.05)
blocker.commit()
thread.join(10)
observer.close()
blocker.close()
assert chain == (waiter_ids[0], blocker_id) and not thread.is_alive() and not errors, (chain, waiter_ids, blocker_id, errors)
print("MySQL blocking chain: waiter -> blocker")
PY
