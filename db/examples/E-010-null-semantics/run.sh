#!/usr/bin/env bash
# E-010-null-semantics · NULL 语义陷阱：不报错但结果错
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_010_null_semantics

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

ns = "db_e_E_010_null_semantics"

conn = pymysql.connect(host="mysql", user="root", password="devbox",
                       database=ns, autocommit=True)
cur = conn.cursor()

def scalar(sql):
    cur.execute(sql)
    return cur.fetchone()[0]

# ---- 1) COUNT(*) 与 COUNT(col) 不是一回事：NULL 行不计入后者 ----
rows = scalar("SELECT COUNT(*) FROM orders")
non_null = scalar("SELECT COUNT(amount) FROM orders")
print(f"count rows={rows} amount_non_null={non_null}")

# ---- 2) 聚合跳过 NULL：北区分母里没有 NULL 那单 ----
print(f"distinct_region={scalar('SELECT COUNT(DISTINCT region) FROM orders')}")
north_sql = "SELECT SUM(amount) FROM orders WHERE region = 'north'"
print(f"north_sum={scalar(north_sql)}")

# ---- 3) 空集聚合返回 NULL 而不是 0：南区全是 NULL 单 ----
south_sql = "SELECT SUM(amount) FROM orders WHERE region = 'south'"
coalesced_sql = "SELECT COALESCE(SUM(amount), 0) FROM orders WHERE region = 'south'"
south = scalar(south_sql)
print(f"south_sum_is_null={'yes' if south is None else 'no'} "
      f"south_sum_coalesced={scalar(coalesced_sql)}")

# ---- 4) = NULL 永远不匹配：比较结果是 UNKNOWN，不是 FALSE ----
eq_null = scalar("SELECT COUNT(*) FROM orders WHERE region = NULL")
is_null = scalar("SELECT COUNT(*) FROM orders WHERE region IS NULL")
print(f"eq_null_matches={eq_null} is_null_matches={is_null}")

# ---- 5) AVG 同样跳过 NULL：分母是 2 不是 5 ----
print(f"avg_amount={float(scalar('SELECT AVG(amount) FROM orders')):g}")

# ---- 6) NOT IN 里混进 NULL：整个谓词对每一行都变 UNKNOWN ----
trap = scalar("SELECT COUNT(*) FROM orders WHERE region NOT IN ('north', NULL)")
fixed = scalar("SELECT COUNT(*) FROM orders "
               "WHERE region IS NULL OR region NOT IN ('north')")
print(f"not_in_trap={trap} not_in_fixed={fixed}")
conn.close()
PY
