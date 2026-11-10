#!/usr/bin/env bash
# E-004-rollback-savepoint · 事务回滚与保存点（含 PG 事务中止态对照）
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_004_rollback_savepoint

if ! tb mysql -h mysql -uroot -N -B -e 'SELECT 1' >/dev/null 2>&1; then
  bash "$DB_ROOT/scripts/up.sh" >/dev/null
  bash "$DB_ROOT/scripts/wait-ready.sh" >/dev/null
fi

cleanup() { mysql_db "DROP DATABASE IF EXISTS $NS" >/dev/null || true; }
trap cleanup EXIT

cleanup
mysql_db "CREATE DATABASE $NS CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
mysql_file "$HERE/schema.sql"

tb python3 - <<'PY'
import os

import pymysql

ns = "db_e_E_004_rollback_savepoint"
conn = pymysql.connect(host="mysql", user="root", password="devbox",
                       database=ns, autocommit=False)
cur = conn.cursor()

# MySQL：语句失败后事务仍可用，SAVEPOINT 支持部分回滚
cur.execute("INSERT INTO tags VALUES (1, 'a')")
cur.execute("INSERT INTO tags VALUES (2, 'b')")
conn.commit()
print("rows_before_savepoint=2")

cur.execute("SAVEPOINT sp1")
try:
    cur.execute("INSERT INTO tags VALUES (3, 'b')")
except pymysql.MySQLError as e:
    print(f"violation err={e.args[0]} rollback_to=sp1")
cur.execute("ROLLBACK TO sp1")
cur.execute("SELECT COUNT(*) FROM tags")
print(f"rows_after_rollback_to={cur.fetchone()[0]}")

cur.execute("INSERT INTO tags VALUES (3, 'c')")
conn.commit()
cur.execute("SELECT COUNT(*) FROM tags")
print(f"rows_final={cur.fetchone()[0]}")
PY

tb python3 - <<'PY'
import psycopg2

pg = psycopg2.connect(host="postgres", user="devbox", password="devbox",
                      dbname="devbox")
pg.autocommit = False
pcur = pg.cursor()

pcur.execute("DROP SCHEMA IF EXISTS e004 CASCADE")
pg.commit()
pcur.execute("CREATE SCHEMA e004")
pcur.execute("CREATE TABLE e004.notes (id INT PRIMARY KEY)")
pg.commit()

# 无保存点：一条语句失败后，整个事务进入 aborted 状态
pcur.execute("BEGIN")
pcur.execute("INSERT INTO e004.notes VALUES (1)")
try:
    pcur.execute("INSERT INTO e004.notes VALUES (1)")
except psycopg2.Error as e:
    print(f"pg_violation err={e.pgcode} class=constraint")
try:
    pcur.execute("SELECT COUNT(*) FROM e004.notes")
    pcur.fetchone()
    print("pg_after_error=still_usable")
except psycopg2.Error as e:
    print(f"pg_after_error err={e.pgcode} class=aborted_txn")
pg.rollback()
pcur.execute("SELECT COUNT(*) FROM e004.notes")
print(f"pg_without_savepoint rows_committed={pcur.fetchone()[0]}")

# 有保存点：回滚到保存点，事务存活并可继续提交
pcur.execute("BEGIN")
pcur.execute("INSERT INTO e004.notes VALUES (1)")
pcur.execute("SAVEPOINT sp")
try:
    pcur.execute("INSERT INTO e004.notes VALUES (1)")
except psycopg2.Error:
    pass
pcur.execute("ROLLBACK TO sp")
pcur.execute("INSERT INTO e004.notes VALUES (2)")
pg.commit()
pcur.execute("SELECT COUNT(*) FROM e004.notes")
print(f"pg_with_savepoint rows_committed={pcur.fetchone()[0]}")

pcur.execute("DROP SCHEMA IF EXISTS e004 CASCADE")
pg.commit()
pg.close()
PY
