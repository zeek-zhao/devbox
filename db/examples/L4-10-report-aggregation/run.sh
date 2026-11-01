#!/usr/bin/env bash
# L4-10-report-aggregation · 报表聚合
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"
MYSQL_NS=db_l4_10_report_aggregation
PG_NS=l4_10_report_aggregation
psql_quiet() { tb psql -h postgres -U devbox -d devbox -t -A -q -v ON_ERROR_STOP=1 -c "$1"; }

mysql_db "DROP DATABASE IF EXISTS $MYSQL_NS; CREATE DATABASE $MYSQL_NS;"
mysql_db "USE $MYSQL_NS;
CREATE TABLE sales (sale_key VARCHAR(16) PRIMARY KEY, amount DECIMAL(10,2) NOT NULL);
CREATE TABLE sales_summary (id INT PRIMARY KEY, total DECIMAL(10,2) NOT NULL);
INSERT INTO sales_summary VALUES (1,0.00);
CREATE TRIGGER sales_after_insert AFTER INSERT ON sales FOR EACH ROW
  UPDATE sales_summary SET total=total+NEW.amount WHERE id=1;
INSERT INTO sales VALUES ('sale-1',10.25),('sale-2',4.75);
SELECT CONCAT('MySQL realtime=',(SELECT ROUND(SUM(amount),2) FROM sales),
              ' summary=',ROUND(total,2),
              ' equal=',IF(ROUND(total,2)=(SELECT ROUND(SUM(amount),2) FROM sales),1,0))
FROM sales_summary WHERE id=1;"

psql_quiet "DROP SCHEMA IF EXISTS $PG_NS CASCADE; CREATE SCHEMA $PG_NS;
CREATE TABLE $PG_NS.sales (sale_key text PRIMARY KEY, amount numeric(10,2) NOT NULL);
INSERT INTO $PG_NS.sales VALUES ('sale-1',10.25),('sale-2',4.75);
CREATE MATERIALIZED VIEW $PG_NS.sales_summary AS
  SELECT ROUND(SUM(amount),2) AS total FROM $PG_NS.sales;
REFRESH MATERIALIZED VIEW $PG_NS.sales_summary;
SELECT 'PostgreSQL realtime='||(SELECT ROUND(SUM(amount),2) FROM $PG_NS.sales)||
       ' summary='||total||
       ' equal='||CASE WHEN total=(SELECT ROUND(SUM(amount),2) FROM $PG_NS.sales)
                       THEN '1' ELSE '0' END
FROM $PG_NS.sales_summary;"
