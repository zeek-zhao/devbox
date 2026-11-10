#!/usr/bin/env bash
# E-011-migration-partial-fail · 迁移中途失败：DML 回滚、DDL 残留与幂等重跑
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_011_migration_partial_fail

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

ns = "db_e_E_011_migration_partial_fail"

conn = pymysql.connect(host="mysql", user="root", password="devbox",
                       database=ns, autocommit=True)
cur = conn.cursor()


def column_exists(table, column):
    cur.execute(
        "SELECT COUNT(*) FROM information_schema.columns "
        "WHERE table_schema = %s AND table_name = %s AND column_name = %s",
        (ns, table, column),
    )
    return cur.fetchone()[0] == 1


# ---- 1) v2 迁移三步：DDL 加列（自动提交）→ 建索引手误 → 回填（还没轮到）----
cur.execute("ALTER TABLE users ADD COLUMN last_login DATETIME NULL")
conn.autocommit(False)
try:
    cur.execute("CREATE INDEX idx_last_login ON users (last_logn)")  # 手误列名
    cur.execute("UPDATE users SET last_login = '2020-01-01 00:00:00'")  # 回填没轮到
    conn.commit()
    raise SystemExit("expected migration step 2 to fail")
except pymysql.MySQLError as e:
    conn.rollback()  # 结束失败的事务；已自动提交的 DDL 回不来
    conn.autocommit(True)
    print(f"migration_failed err={e.args[0]} rollback_done=yes")

# ---- 2) 检测部分应用：DDL 已生效、索引与回填缺失——迁移卡在「半套」状态 ----
print(f"partial_applied last_login_column={'yes' if column_exists('users', 'last_login') else 'no'}")
cur.execute("SELECT COUNT(*) FROM users WHERE last_login IS NOT NULL")
print(f"backfill_committed={cur.fetchone()[0]}")

# ---- 3) 幂等重跑：每步先探测再执行，跳过已应用部分，补上失败的步骤 ----
if not column_exists("users", "last_login"):
    cur.execute("ALTER TABLE users ADD COLUMN last_login DATETIME NULL")
conn.autocommit(False)
cur.execute("CREATE INDEX idx_last_login ON users (last_login)")
cur.execute("UPDATE users SET last_login = '2020-01-01 00:00:00'")
conn.commit()
conn.autocommit(True)
cur.execute("INSERT INTO schema_migrations (version, name) VALUES (2, 'add-last-login')")
cur.execute("SELECT COUNT(*) FROM users WHERE last_login IS NOT NULL")
print(f"rerun backfill_committed={cur.fetchone()[0]}")
cur.execute("SELECT COUNT(*) FROM schema_migrations WHERE version = 2")
print(f"version_recorded={cur.fetchone()[0]}")

# ---- 4) 不带防护的重复迁移：撞 1060，捕获后按「已应用」处理而不是告警 ----
try:
    cur.execute("ALTER TABLE users ADD COLUMN last_login DATETIME NULL")
    raise SystemExit("expected duplicate column error")
except pymysql.MySQLError as e:
    print(f"duplicate_column err={e.args[0]} handled=idempotent")
conn.close()
PY
