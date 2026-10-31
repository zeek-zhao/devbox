#!/usr/bin/env bash
# L4-04-idempotency · 幂等设计
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"
NS=db_l4_04_idempotency

mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"
mysql_db "USE $NS;
CREATE TABLE unique_orders (
  request_key VARCHAR(32) NOT NULL UNIQUE,
  payload VARCHAR(32) NOT NULL
);
INSERT INTO unique_orders VALUES ('req-1','first');
INSERT IGNORE INTO unique_orders VALUES ('req-1','retry');
SELECT CONCAT('unique-key orders=',COUNT(*)) FROM unique_orders;
CREATE TABLE idempotency_records (
  request_key VARCHAR(32) PRIMARY KEY,
  response_body VARCHAR(64) NOT NULL
);
CREATE TABLE token_orders (
  request_key VARCHAR(32) PRIMARY KEY,
  payload VARCHAR(32) NOT NULL
);
INSERT INTO token_orders
SELECT 'req-2','first'
WHERE NOT EXISTS (SELECT 1 FROM idempotency_records WHERE request_key='req-2');
INSERT INTO idempotency_records VALUES ('req-2','order=req-2;payload=first');
INSERT INTO token_orders
SELECT 'req-2','retry'
WHERE NOT EXISTS (SELECT 1 FROM idempotency_records WHERE request_key='req-2');
INSERT IGNORE INTO idempotency_records VALUES ('req-2','order=req-2;payload=retry');
SELECT CONCAT('token orders=',(SELECT COUNT(*) FROM token_orders),
              ' replay=',response_body)
FROM idempotency_records WHERE request_key='req-2';"
