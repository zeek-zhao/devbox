#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l2_04_txn_boundary_deadlock
psql_db "DROP DATABASE IF EXISTS $NS" >/dev/null
psql_db "CREATE DATABASE $NS" >/dev/null

python_file="$(mktemp)"
trap 'rm -f "$python_file"' EXIT
cat >"$python_file" <<'PY'
import threading

import psycopg2

database = "db_l2_04_txn_boundary_deadlock"
setup = psycopg2.connect(
    host="postgres", dbname=database, user="devbox", password="devbox",
)
with setup:
    with setup.cursor() as cur:
        cur.execute("CREATE TABLE accounts (id integer PRIMARY KEY, balance integer NOT NULL)")
        cur.execute("INSERT INTO accounts VALUES (1, 0), (2, 0)")
setup.close()

barrier = threading.Barrier(2)
deadlocks = []
failures = []


def connect():
    return psycopg2.connect(
        host="postgres", dbname=database, user="devbox", password="devbox",
    )


def transfer(first_id, second_id, amount):
    conn = connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET deadlock_timeout = '100ms'")
            cur.execute("UPDATE accounts SET balance = balance + %s WHERE id = %s",
                        (amount, first_id))
            barrier.wait(timeout=5)
            cur.execute("UPDATE accounts SET balance = balance + %s WHERE id = %s",
                        (amount, second_id))
        conn.commit()
    except psycopg2.errors.DeadlockDetected as exc:
        deadlocks.append(exc.pgcode)
        conn.rollback()
        try:
            with conn.cursor() as cur:
                cur.execute("UPDATE accounts SET balance = balance + %s WHERE id = %s",
                            (amount, first_id))
                cur.execute("UPDATE accounts SET balance = balance + %s WHERE id = %s",
                            (amount, second_id))
            conn.commit()
        except Exception as retry_error:
            conn.rollback()
            failures.append(retry_error)
    except Exception as exc:
        conn.rollback()
        failures.append(exc)
    finally:
        conn.close()


threads = [
    threading.Thread(target=transfer, args=(1, 2, 1)),
    threading.Thread(target=transfer, args=(2, 1, 10)),
]
for thread in threads:
    thread.start()
for thread in threads:
    thread.join(timeout=8)
if any(thread.is_alive() for thread in threads):
    raise RuntimeError("deadlock demonstration did not finish")
if failures:
    raise failures[0]
if len(deadlocks) != 1 or deadlocks[0] != "40P01":
    raise RuntimeError(f"expected one PostgreSQL deadlock, got {deadlocks!r}")

verify = connect()
try:
    with verify.cursor() as cur:
        cur.execute("SELECT id, balance FROM accounts ORDER BY id")
        rows = cur.fetchall()
finally:
    verify.close()
print(f"deadlock SQLSTATE={deadlocks[0]}")
print("victim retry=committed")
print(f"balances={rows}")
PY
py_file "$python_file"
