#!/usr/bin/env bash
# E-014-fk-cascade-trap · 外键级联：1451 拒绝是护栏，CASCADE 是静默丢失通道
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_014_fk_cascade_trap

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

ns = "db_e_E_014_fk_cascade_trap"

conn = pymysql.connect(host="mysql", user="root", password="devbox",
                       database=ns, autocommit=True)
cur = conn.cursor()

# ---- 1) RESTRICT 外键：删被引用的父行被 1451 拒绝——这是护栏不是故障 ----
try:
    cur.execute("DELETE FROM customers WHERE id = 1")
    raise SystemExit("expected 1451 for referenced parent")
except pymysql.MySQLError as e:
    print(f"delete_parent err={e.args[0]} class=foreign_key action=handle_children")

# ---- 2) 正确处理：显式两步走，同事务里先归档子行再删父行 ----
conn.autocommit(False)
cur.execute("UPDATE orders SET note = 'archived' WHERE customer_id = 1")
cur.execute("DELETE FROM orders WHERE customer_id = 1")
cur.execute("DELETE FROM customers WHERE id = 1")
conn.commit()
conn.autocommit(True)
cur.execute("SELECT COUNT(*) FROM orders WHERE customer_id = 1")
left_orders = cur.fetchone()[0]
cur.execute("SELECT COUNT(*) FROM customers WHERE id = 1")
left_customers = cur.fetchone()[0]
print(f"explicit_two_step orders_left={left_orders} customer_gone={'yes' if left_customers == 0 else 'no'}")

# ---- 3) CASCADE 外键：同一句 DELETE 静默带走两张发票——错误处理视角下这是数据丢失 ----
cur.execute("SELECT COUNT(*) FROM invoices WHERE customer_id = 2")
before = cur.fetchone()[0]
cur.execute("DELETE FROM customers WHERE id = 2")
cur.execute("SELECT COUNT(*) FROM invoices WHERE customer_id = 2")
after = cur.fetchone()[0]
print(f"cascade_delete invoices_before={before} invoices_after={after} silent_loss={'yes' if before > 0 and after == 0 else 'no'}")
cur.execute("SELECT COUNT(*) FROM customers")
print(f"customers_left={cur.fetchone()[0]}")
conn.close()
PY
