#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

db=db_l3_10_archive_cold_hot
mysql_db "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db; USE $db; CREATE TABLE hot_orders (id INT PRIMARY KEY, order_day DATE NOT NULL, amount DECIMAL(10,2) NOT NULL); CREATE TABLE cold_orders LIKE hot_orders; INSERT INTO hot_orders VALUES (1,'2025-01-01',10.00),(2,'2026-06-01',20.00),(3,'2024-12-31',30.00);"
mysql_db "SELECT CONCAT('hot before archive: ', COUNT(*)) FROM $db.hot_orders;"
mysql_db "START TRANSACTION; INSERT INTO $db.cold_orders SELECT * FROM $db.hot_orders WHERE order_day < '2026-01-01'; DELETE FROM $db.hot_orders WHERE order_day < '2026-01-01'; COMMIT; SELECT CONCAT('hot after archive: ', COUNT(*)) FROM $db.hot_orders; SELECT CONCAT('cold archive rows: ', COUNT(*)) FROM $db.cold_orders;"
