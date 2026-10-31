#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

db=db_l3_12_audit_log
mysql_db "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db; USE $db; CREATE TABLE accounts (id INT PRIMARY KEY, balance DECIMAL(10,2) NOT NULL); CREATE TABLE audit_log (event_name VARCHAR(32) NOT NULL, account_id INT NOT NULL); CREATE TRIGGER accounts_update_audit AFTER UPDATE ON accounts FOR EACH ROW INSERT INTO audit_log VALUES ('BALANCE_UPDATE', NEW.id); INSERT INTO accounts VALUES (1,100.00);"
mysql_db "UPDATE $db.accounts SET balance=balance-10.00 WHERE id=1; SELECT CONCAT('sensitive operations audited: ', COUNT(*)) FROM $db.audit_log WHERE event_name='BALANCE_UPDATE'; SELECT event_name, account_id FROM $db.audit_log ORDER BY event_name, account_id;"
