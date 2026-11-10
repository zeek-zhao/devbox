#!/usr/bin/env bash
# E-012-upsert-race · 唯一键竞态：INSERT 撞车 1062 与 upsert 收口
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_012_upsert_race

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
import threading
import time

import pymysql

ns = "db_e_E_012_upsert_race"


def connect():
    return pymysql.connect(host="mysql", user="root", password="devbox",
                           database=ns, autocommit=False)


# ---- 1) 竞态输家：会话 B 的 INSERT 撞上会话 A 未提交的同键插入，B 阻塞；
#         A 提交后 B 才被放行，拿到 1062 —— 不是「立刻报错」的重复键 ----
a, b = connect(), connect()
ac, bc = a.cursor(), b.cursor()
bc.execute("SET SESSION innodb_lock_wait_timeout = 5")
ac.execute("INSERT INTO sku_stock (sku, qty) VALUES ('widget-b', 1)")
commit_later = threading.Timer(1.0, a.commit)
commit_later.start()
try:
    bc.execute("INSERT INTO sku_stock (sku, qty) VALUES ('widget-b', 1)")
    raise SystemExit("expected the losing INSERT to fail with 1062")
except pymysql.MySQLError as e:
    print(f"race_commit err={e.args[0]} action=adopt_existing")
commit_later.join()
b.rollback()  # 1062 之前的事务里可能还有别的写入，先干净地结束

# 输家不重插，改为采用已存在的行（get-or-create 的读侧）
bc.execute("SELECT sku, qty FROM sku_stock WHERE sku = 'widget-b'")
sku, qty = bc.fetchone()
print(f"adopted sku={sku} qty={qty}")

# ---- 2) 竞态翻转：A 回滚 → 同一个「输家」反而插入成功 ----
a2, b2 = connect(), connect()
a2c, b2c = a2.cursor(), b2.cursor()
b2c.execute("SET SESSION innodb_lock_wait_timeout = 5")
a2c.execute("INSERT INTO sku_stock (sku, qty) VALUES ('widget-c', 1)")
rollback_later = threading.Timer(1.0, a2.rollback)
rollback_later.start()
try:
    b2c.execute("INSERT INTO sku_stock (sku, qty) VALUES ('widget-c', 1)")
    b2.commit()
    print("race_rollback loser_ok=yes")
except pymysql.MySQLError as e:
    print(f"race_rollback err={e.args[0]}")
rollback_later.join()
a2.rollback()
a.close(); b.close(); a2.close(); b2.close()

# ---- 3) 惯用收口：ON DUPLICATE KEY UPDATE 把竞态交给数据库，且计数不丢 ----
u1, u2 = connect(), connect()
u1c, u2c = u1.cursor(), u2.cursor()
u1c.execute("UPDATE sku_stock SET qty = 100 WHERE sku = 'widget-a'")
u1.commit()
u1c.execute("INSERT INTO sku_stock (sku, qty) VALUES ('widget-a', 0) "
            "ON DUPLICATE KEY UPDATE qty = qty + 5")  # 持行锁未提交
commit_u1 = threading.Timer(1.0, u1.commit)
commit_u1.start()
u2c.execute("INSERT INTO sku_stock (sku, qty) VALUES ('widget-a', 0) "
            "ON DUPLICATE KEY UPDATE qty = qty + 5")  # 等锁，u1 提交后放行
u2.commit()
commit_u1.join()
u1c.execute("SELECT qty FROM sku_stock WHERE sku = 'widget-a'")
print(f"upsert_concurrent qty={u1c.fetchone()[0]} lost_update=no")
u1.close(); u2.close()
PY
