#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

db=db_l2_12_data_integrity
mysql_db "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db; USE $db; CREATE TABLE parent (id INT PRIMARY KEY) ENGINE=InnoDB; CREATE TABLE child (id INT PRIMARY KEY, parent_id INT NOT NULL, CONSTRAINT fk_parent FOREIGN KEY (parent_id) REFERENCES parent(id)) ENGINE=InnoDB; INSERT INTO parent VALUES (1);"
mysql_db "USE $db; SET FOREIGN_KEY_CHECKS=0; INSERT INTO child VALUES (1, 999); SET FOREIGN_KEY_CHECKS=1;"
mysql_db "USE $db; SELECT CONCAT('orphan rows: ', COUNT(*)) FROM child c LEFT JOIN parent p ON p.id=c.parent_id WHERE p.id IS NULL;"
mysql_db "USE $db; DELETE c FROM child c LEFT JOIN parent p ON p.id=c.parent_id WHERE p.id IS NULL; SELECT CONCAT('orphan rows after repair: ', COUNT(*)) FROM child c LEFT JOIN parent p ON p.id=c.parent_id WHERE p.id IS NULL;"
tb python3 - <<'PY'
import pymysql
conn = pymysql.connect(host="mysql", user="root", password="devbox", database="db_l2_12_data_integrity")
with conn.cursor() as cur:
    cur.execute("CHECKSUM TABLE parent, child")
    checksums = cur.fetchall()
assert len(checksums) == 2 and all(row[1] is not None for row in checksums), checksums
print("small-table checksums: computed")
conn.close()
PY
