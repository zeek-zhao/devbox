#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh
mysql_db "DROP DATABASE IF EXISTS db_l2_14_big_table_ddl; CREATE DATABASE db_l2_14_big_table_ddl;"
tb python3 - <<'PY'
import threading
import pymysql

def connect():
    return pymysql.connect(host="mysql", user="root", password="devbox", database="db_l2_14_big_table_ddl", autocommit=True)

conn = connect()
with conn.cursor() as cur:
    cur.execute("CREATE TABLE records (id INT PRIMARY KEY, payload VARCHAR(80) NOT NULL) ENGINE=InnoDB")
    cur.executemany("INSERT INTO records VALUES (%s,%s)", [(i, f"value-{i % 997}") for i in range(1, 50001)])
conn.close()

started = threading.Event()
results = []
def add_index():
    c = connect()
    try:
        started.set()
        with c.cursor() as cur:
            cur.execute("ALTER TABLE records ADD INDEX idx_payload(payload), ALGORITHM=INPLACE, LOCK=NONE")
        results.append("ok")
    except Exception as exc:
        results.append(str(exc))
    finally:
        c.close()

def concurrent_write():
    assert started.wait(5)
    c = connect()
    try:
        with c.cursor() as cur:
            cur.execute("INSERT INTO records VALUES (50001,'concurrent-write')")
        results.append("write-ok")
    except Exception as exc:
        results.append(str(exc))
    finally:
        c.close()

ddl = threading.Thread(target=add_index)
writer = threading.Thread(target=concurrent_write)
ddl.start()
writer.start()
ddl.join(60)
writer.join(60)
assert not ddl.is_alive() and not writer.is_alive() and "ok" in results and "write-ok" in results, results
print("index algorithm: INPLACE, LOCK=NONE")
print("concurrent write: succeeded")
PY
