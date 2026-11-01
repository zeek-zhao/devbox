#!/usr/bin/env bash
# L1-MY-05-transaction · 事务与隔离级别
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_my_05_transaction
mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"
tb python3 - <<'PY'
import pymysql

settings = dict(host="mysql", user="root", password="devbox",
                database="db_l1_my_05_transaction")
with pymysql.connect(**settings) as setup:
    with setup.cursor() as cur:
        cur.execute("CREATE TABLE balances (account VARCHAR(12) PRIMARY KEY, amount INT NOT NULL)")
        cur.execute("INSERT INTO balances VALUES ('checking', 10)")
    setup.commit()

first = pymysql.connect(**settings, autocommit=False)
second = pymysql.connect(**settings, autocommit=False)
try:
    with first.cursor() as cur1, second.cursor() as cur2:
        cur1.execute("SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ")
        cur1.execute("START TRANSACTION")
        cur1.execute("SELECT amount FROM balances WHERE account = 'checking'")
        print(f"snapshot_first={cur1.fetchone()[0]}")

        cur2.execute("START TRANSACTION")
        cur2.execute("UPDATE balances SET amount = 20 WHERE account = 'checking'")
        second.commit()

        cur1.execute("SELECT amount FROM balances WHERE account = 'checking'")
        print(f"snapshot_after_commit={cur1.fetchone()[0]}")
        cur1.execute("SELECT amount FROM balances WHERE account = 'checking' FOR UPDATE")
        print(f"current_read={cur1.fetchone()[0]}")

        cur1.execute("UPDATE balances SET amount = 30 WHERE account = 'checking'")
        first.rollback()
        cur2.execute("SELECT amount FROM balances WHERE account = 'checking'")
        print(f"after_rollback={cur2.fetchone()[0]}")
finally:
    first.close()
    second.close()
PY
