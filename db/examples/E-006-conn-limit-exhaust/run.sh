#!/usr/bin/env bash
# E-006-conn-limit-exhaust · 连接数耗尽（容量类错误）的归因与让路
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_006_conn_limit_exhaust

# 自包含：栈没起来就先起（up.sh / wait-ready.sh 都幂等）
if ! tb mysql -h mysql -uroot -N -B -e 'SELECT 1' >/dev/null 2>&1; then
  bash "$DB_ROOT/scripts/up.sh" >/dev/null
  bash "$DB_ROOT/scripts/wait-ready.sh" >/dev/null
fi

cleanup() {
  mysql_db "DROP DATABASE IF EXISTS $NS" >/dev/null || true
  mysql_db "DROP USER IF EXISTS 'app_shed'@'%'" >/dev/null || true
}
trap cleanup EXIT

cleanup
mysql_db "CREATE DATABASE $NS CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
mysql_file "$HERE/schema.sql"

# 演示专用账号：MAX_USER_CONNECTIONS 2 把服务端配额做小、可复现，
# 避免靠打满全局 max_connections（那会砸掉共享栈上其他用例）。
mysql_db "CREATE USER IF NOT EXISTS 'app_shed'@'%' IDENTIFIED BY 'shed-pass-123' WITH MAX_USER_CONNECTIONS 2"
mysql_db "GRANT ALL ON $NS.* TO 'app_shed'@'%'"

tb python3 - <<'PY'
import pymysql

ns = "db_e_E_006_conn_limit_exhaust"


def classify(code):
    if code in (1040, 1226):
        return "capacity", "shed"
    if code in (2003, 2002, 2006, 2013):
        return "environment", "retry"
    return "unknown", "no"


def connect():
    return pymysql.connect(host="mysql", user="app_shed",
                           password="shed-pass-123", database=ns)


# 1) 正常租借到服务端配额（MAX_USER_CONNECTIONS=2）
pool = []
for i in (1, 2):
    pool.append(connect())
    print(f"lease conn={i} ok")

# 2) 超配额的第 3 个申请：服务端拒绝。这是容量类错误，不是网络错误
try:
    connect()
    raise SystemExit("expected the 3rd lease to be rejected")
except pymysql.MySQLError as e:
    code = e.args[0]
    cat, action = classify(code)
    print(f"lease_exceeded err={code} class={cat} action={action}")

# 3) 正确处理：容量错误重试没有意义，先释放一个租约把容量还回去，再重试
pool[0].close()
pool = pool[1:]
print("release conn=1 freed=yes")

c = connect()
cur = c.cursor()
cur.execute("INSERT INTO lease_log (note) VALUES ('leased_after_shed')")
c.commit()
print("retry lease ok=yes")
print("pool_active=2")

cur.execute("SELECT COUNT(*) FROM lease_log")
print(f"log_rows={cur.fetchone()[0]}")
c.close()
for p in pool:
    p.close()
PY
