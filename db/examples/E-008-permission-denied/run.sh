#!/usr/bin/env bash
# E-008-permission-denied · 权限拒绝（1044/1142）的归因与修复路径
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_008_permission_denied

if ! tb mysql -h mysql -uroot -N -B -e 'SELECT 1' >/dev/null 2>&1; then
  bash "$DB_ROOT/scripts/up.sh" >/dev/null
  bash "$DB_ROOT/scripts/wait-ready.sh" >/dev/null
fi

cleanup() {
  mysql_db "DROP DATABASE IF EXISTS $NS" >/dev/null || true
  mysql_db "DROP USER IF EXISTS 'app_ro'@'%'" >/dev/null || true
  mysql_db "DROP USER IF EXISTS 'app_none'@'%'" >/dev/null || true
}
trap cleanup EXIT

cleanup
mysql_db "CREATE DATABASE $NS CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
mysql_file "$HERE/schema.sql"

# 只读账号 + 无库权限账号：把权限错误做小、可复现，不用 root 撞墙
mysql_db "CREATE USER IF NOT EXISTS 'app_ro'@'%' IDENTIFIED BY 'ro-pass-123'"
mysql_db "CREATE USER IF NOT EXISTS 'app_none'@'%' IDENTIFIED BY 'none-pass-123'"
mysql_db "GRANT SELECT ON $NS.* TO 'app_ro'@'%'"

tb python3 - <<'PY'
import pymysql

ns = "db_e_E_008_permission_denied"


def classify(code):
    if code in (1044, 1045, 1142, 1143, 1144):
        return "permission", "grant_or_fix_caller"
    return "unknown", "no"


def connect(user, password, database=ns):
    return pymysql.connect(host="mysql", user=user, password=password,
                           database=database)


# ---- 1) 有 SELECT 权：读得通 ----
ro = connect("app_ro", "ro-pass-123")
ro_cur = ro.cursor()
ro_cur.execute("SELECT note FROM secrets ORDER BY id")
print(f"select_ok rows={len(ro_cur.fetchall())}")

# ---- 2) 没有 INSERT 权：1142，不可重试，动作是补授权 ----
try:
    ro_cur.execute("INSERT INTO secrets (note) VALUES ('x')")
    raise SystemExit("expected INSERT to be denied")
except pymysql.MySQLError as e:
    code = e.args[0]
    print(f"insert_denied err={code} class={classify(code)[0]} retryable=no")

# ---- 3) 修复路径：GRANT 后用新连接验证（授权表对会话有缓存语义）----
root = pymysql.connect(host="mysql", user="root", password="devbox",
                       database=ns, autocommit=True)
root_cur = root.cursor()
root_cur.execute(f"GRANT INSERT ON {ns}.* TO 'app_ro'@'%'")
ro_fixed = connect("app_ro", "ro-pass-123")
ro_fixed.cursor().execute("INSERT INTO secrets (note) VALUES ('granted-late')")
ro_fixed.commit()
print("grant_fixed insert_ok=1")

# ---- 4) REVOKE 立刻关上门：新连接同样被拒 ----
root_cur.execute(f"REVOKE INSERT ON {ns}.* FROM 'app_ro'@'%'")
ro_revoked = connect("app_ro", "ro-pass-123")
try:
    ro_revoked.cursor().execute("INSERT INTO secrets (note) VALUES ('should-fail')")
    raise SystemExit("expected INSERT to be denied after REVOKE")
except pymysql.MySQLError as e:
    print(f"revoked err={e.args[0]} closed=yes")
ro_fixed.close()
ro_revoked.close()

# ---- 5) 连库都没有权限：1044，连接阶段就拒绝 ----
try:
    connect("app_none", "none-pass-123")
    raise SystemExit("expected connect to be denied")
except pymysql.MySQLError as e:
    code = e.args[0]
    print(f"no_db_access err={code} class={classify(code)[0]} retryable=no")

ro.close()
root.close()
PY
