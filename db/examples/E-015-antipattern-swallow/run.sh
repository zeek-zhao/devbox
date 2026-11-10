#!/usr/bin/env bash
# E-015-antipattern-swallow · 反模式对照：autocommit 滥用 + 吞错 = 半套落库
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_015_antipattern_swallow

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
import pymysql

ns = "db_e_E_015_antipattern_swallow"


def connect():
    return pymysql.connect(host="mysql", user="root", password="devbox",
                           database=ns, autocommit=True)


def reset():
    c = connect()
    cur = c.cursor()
    cur.execute("UPDATE wallets SET bal = 100")
    c.close()


def total():
    c = connect()
    cur = c.cursor()
    cur.execute("SELECT id, bal FROM wallets ORDER BY id")
    rows = cur.fetchall()
    c.close()
    return rows


# ---- 反模式：autocommit 模式下每条语句自成事务，第二条失败被 except: pass 吞掉 ----
reset()
bad = connect()
bcur = bad.cursor()
bcur.execute("UPDATE wallets SET bal = bal - 30 WHERE id = 1")  # 已自动提交
try:
    bcur.execute("UPDATE wallets SET bal = bal + 90000000000000000000 WHERE id = 2")
except pymysql.MySQLError:
    pass  # 吞错：看起来「处理了」，实际什么都没处理
bad.close()
rows = total()
print("antipattern " + " ".join(f"id={r[0]} bal={r[1]}" for r in rows))
print(f"antipattern sum={sum(r[1] for r in rows)} lost=30 reported=no")

# ---- 正路：显式事务 + 不吞错：失败即整体回滚，错误上抛 ----
reset()
good = pymysql.connect(host="mysql", user="root", password="devbox",
                       database=ns, autocommit=False)
gcur = good.cursor()
try:
    gcur.execute("UPDATE wallets SET bal = bal - 30 WHERE id = 1")
    gcur.execute("UPDATE wallets SET bal = bal + 90000000000000000000 WHERE id = 2")
    good.commit()
except pymysql.MySQLError as e:
    good.rollback()
    print(f"handled err={e.args[0]} rollback=yes reported=yes")
good.close()
rows = total()
print("handled " + " ".join(f"id={r[0]} bal={r[1]}" for r in rows))
print(f"handled sum={sum(r[1] for r in rows)} lost=0 consistent=yes")
PY
