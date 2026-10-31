#!/usr/bin/env bash
# L4-05-multi-tenant · 多租户隔离
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"
MYSQL_NS_A=db_l4_05_tenant_a
MYSQL_NS_B=db_l4_05_tenant_b
MYSQL_USER=l4_05_tenant_a
psql_quiet() { tb psql -h postgres -U devbox -d devbox -t -A -q -v ON_ERROR_STOP=1 -c "$1"; }
tenant_mysql() { tb env MYSQL_PWD=tenant-a-test mysql -h mysql -u "$MYSQL_USER" -N -B "$@"; }

mysql_db "DROP USER IF EXISTS '$MYSQL_USER'@'%';
DROP DATABASE IF EXISTS $MYSQL_NS_A; DROP DATABASE IF EXISTS $MYSQL_NS_B;
CREATE DATABASE $MYSQL_NS_A; CREATE DATABASE $MYSQL_NS_B;"
mysql_db "USE $MYSQL_NS_A; CREATE TABLE records (tenant_key CHAR(1) PRIMARY KEY, value VARCHAR(20)); INSERT INTO records VALUES ('A','alpha');"
mysql_db "USE $MYSQL_NS_B; CREATE TABLE records (tenant_key CHAR(1) PRIMARY KEY, value VARCHAR(20)); INSERT INTO records VALUES ('B','bravo');"
mysql_db "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY 'tenant-a-test';
GRANT SELECT ON $MYSQL_NS_A.* TO '$MYSQL_USER'@'%';"
printf 'independent databases: A db A rows=%s A db B rows=%s B db rows=%s\n' \
  "$(mysql_db "SELECT COUNT(*) FROM $MYSQL_NS_A.records;")" \
  "$(mysql_db "SELECT COUNT(*) FROM $MYSQL_NS_A.records WHERE tenant_key='B';")" \
  "$(mysql_db "SELECT COUNT(*) FROM $MYSQL_NS_B.records;")"
printf 'A account rows=%s\n' "$(tenant_mysql -e "SELECT COUNT(*) FROM $MYSQL_NS_A.records;")"
err="$(mktemp)"
if tenant_mysql -e "SELECT COUNT(*) FROM $MYSQL_NS_B.records;" >/dev/null 2>"$err"; then
  rm -f "$err"
  die "tenant account unexpectedly read the other database"
elif grep -q 'ERROR 1142' "$err"; then
  echo "independent database cross-access=BLOCKED (1142)"
else
  cat "$err" >&2
  rm -f "$err"
  die "tenant database probe failed for an unexpected reason"
fi
rm -f "$err"

psql_quiet "DROP SCHEMA IF EXISTS l4_05_tenant_a CASCADE;
DROP SCHEMA IF EXISTS l4_05_tenant_b CASCADE;
DROP TABLE IF EXISTS public.shared_orders CASCADE;
DROP ROLE IF EXISTS tenant_a;
CREATE ROLE tenant_a;
CREATE SCHEMA l4_05_tenant_a;
CREATE SCHEMA l4_05_tenant_b;
CREATE TABLE l4_05_tenant_a.records (tenant_key text, value text);
CREATE TABLE l4_05_tenant_b.records (tenant_key text, value text);
INSERT INTO l4_05_tenant_a.records VALUES ('A','alpha');
INSERT INTO l4_05_tenant_b.records VALUES ('B','bravo');
GRANT USAGE ON SCHEMA l4_05_tenant_a TO tenant_a;
GRANT SELECT ON l4_05_tenant_a.records TO tenant_a;
CREATE FUNCTION l4_05_tenant_a.probe_other_schema() RETURNS text
LANGUAGE plpgsql AS \$\$ BEGIN
  EXECUTE 'SELECT count(*) FROM l4_05_tenant_b.records';
  RETURN 'UNEXPECTED';
EXCEPTION WHEN insufficient_privilege THEN RETURN 'BLOCKED';
END \$\$;
GRANT EXECUTE ON FUNCTION l4_05_tenant_a.probe_other_schema() TO tenant_a;
CREATE TABLE shared_orders (tenant_key text, value text);
INSERT INTO shared_orders VALUES ('A','alpha'),('B','bravo');
ALTER TABLE shared_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_orders FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_rows ON shared_orders
  USING (tenant_key=CASE current_user WHEN 'tenant_a' THEN 'A' ELSE 'B' END)
  WITH CHECK (tenant_key=CASE current_user WHEN 'tenant_a' THEN 'A' ELSE 'B' END);
GRANT SELECT,UPDATE ON shared_orders TO tenant_a;
CREATE FUNCTION l4_05_tenant_a.try_cross_update() RETURNS integer
LANGUAGE plpgsql AS \$\$ DECLARE changed integer; BEGIN
  UPDATE shared_orders SET value='tampered' WHERE tenant_key='B';
  GET DIAGNOSTICS changed = ROW_COUNT;
  RETURN changed;
END \$\$;
GRANT EXECUTE ON FUNCTION l4_05_tenant_a.try_cross_update() TO tenant_a;
"

psql_quiet "SET ROLE tenant_a;
SELECT 'schema A rows='||count(*) FROM l4_05_tenant_a.records;
SELECT 'schema cross-access='||l4_05_tenant_a.probe_other_schema();
SELECT 'shared-table visible rows='||count(*) FROM shared_orders;
SELECT 'cross-tenant update rows='||l4_05_tenant_a.try_cross_update();
RESET ROLE;"
mysql_db "DROP USER '$MYSQL_USER'@'%';"
