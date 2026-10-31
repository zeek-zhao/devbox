#!/usr/bin/env bash
# L4-01-order-modeling · 订单模型建模
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"
NS=db_l4_01_order_modeling

mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"
mysql_db "USE $NS;
CREATE TABLE products (
  product_id INT PRIMARY KEY,
  name VARCHAR(40) NOT NULL,
  current_price DECIMAL(10,2) NOT NULL
);
CREATE TABLE orders (
  order_key VARCHAR(24) PRIMARY KEY,
  status ENUM('pending','paid','cancelled') NOT NULL
);
CREATE TABLE order_items (
  order_key VARCHAR(24) NOT NULL,
  line_no INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (order_key, line_no),
  FOREIGN KEY (order_key) REFERENCES orders(order_key),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);
INSERT INTO products VALUES (7,'tea',10.00);
INSERT INTO orders VALUES ('order-A','paid');
INSERT INTO order_items VALUES ('order-A',1,7,2,10.00);
UPDATE products SET current_price=12.00 WHERE product_id=7;
SELECT CONCAT(table_name,':',GROUP_CONCAT(column_name ORDER BY ordinal_position))
FROM information_schema.columns
WHERE table_schema='$NS' AND table_name IN ('orders','order_items','products')
GROUP BY table_name ORDER BY table_name;
SELECT o.order_key, o.status, i.quantity, i.unit_price,
       ROUND(i.quantity*i.unit_price,2) AS snapshot_total,
       ROUND(i.quantity*p.current_price,2) AS live_join_total
FROM orders o
JOIN order_items i ON i.order_key=o.order_key
JOIN products p ON p.product_id=i.product_id
ORDER BY o.order_key, i.line_no;"
