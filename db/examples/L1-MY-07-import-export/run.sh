#!/usr/bin/env bash
# L1-MY-07-import-export · 导入导出
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

SRC=db_l1_my_07_import_export
DST=db_l1_my_07_import_export_restore
DUMP_BASE=/tmp/db_l1_my_07_import_export
mysql_db "DROP DATABASE IF EXISTS $SRC; DROP DATABASE IF EXISTS $DST; CREATE DATABASE $SRC; CREATE DATABASE $DST;"
tb rm -f "$DUMP_BASE.schema.sql" "$DUMP_BASE.data.sql"
cleanup() { tb rm -f "$DUMP_BASE.schema.sql" "$DUMP_BASE.data.sql"; }
trap cleanup EXIT

SQL="$(mktemp)"
trap 'rm -f "$SQL"; cleanup' EXIT
cat >"$SQL" <<'SQL'
USE db_l1_my_07_import_export;
CREATE TABLE shipments (shipment_key VARCHAR(16) PRIMARY KEY, destination VARCHAR(32) NOT NULL, units INT NOT NULL);
INSERT INTO shipments VALUES ('s-1','Osaka',3), ('s-2','Lima',8), ('s-3','Oslo',2);
SQL
mysql_file "$SQL"

tb sh -c "mysqldump -h mysql -uroot --skip-comments --compact --no-data $SRC shipments > '$DUMP_BASE.schema.sql'"
tb sh -c "mysqldump -h mysql -uroot --skip-comments --compact --skip-extended-insert --no-create-info $SRC shipments > '$DUMP_BASE.data.sql'"
exported_rows="$(tb sh -c "grep -c '^INSERT INTO' '$DUMP_BASE.data.sql'")"
tb sh -c "mysql -h mysql -uroot $DST < '$DUMP_BASE.schema.sql'"
tb sh -c "mysql -h mysql -uroot $DST < '$DUMP_BASE.data.sql'"
restored_rows="$(mysql_db "SELECT COUNT(*) FROM $DST.shipments;")"
printf 'dump_rows=%s\nrestored_rows=%s\n' "$exported_rows" "$restored_rows"
