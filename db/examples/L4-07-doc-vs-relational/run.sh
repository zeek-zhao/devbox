#!/usr/bin/env bash
# L4-07-doc-vs-relational · 文档 vs 关系建模
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"
script="$(mktemp)"
trap 'rm -f "$script"' EXIT

cat >"$script" <<'PY'
import pymongo
import pymysql

mysql = pymysql.connect(host="mysql", user="root", password="devbox",
                        autocommit=True)
with mysql.cursor() as cur:
    cur.execute("DROP DATABASE IF EXISTS db_l4_07_doc_vs_relational")
    cur.execute("CREATE DATABASE db_l4_07_doc_vs_relational")
    cur.execute("USE db_l4_07_doc_vs_relational")
    cur.execute("CREATE TABLE orders (order_key VARCHAR(24) PRIMARY KEY, customer VARCHAR(24))")
    cur.execute("CREATE TABLE items (order_key VARCHAR(24), line_no INT, sku VARCHAR(24), "
                "PRIMARY KEY(order_key,line_no))")
    cur.execute("INSERT INTO orders VALUES ('order-A','customer-A')")
    cur.executemany("INSERT INTO items VALUES ('order-A',%s,%s)",
                    [(1, "tea"), (2, "rice")])
    cur.execute("SELECT o.order_key,o.customer,i.sku FROM orders o "
                "JOIN items i ON i.order_key=o.order_key "
                "WHERE o.order_key='order-A' ORDER BY i.line_no")
    sql_rows = cur.fetchall()
print(f"MySQL normalized join: roundtrips=1 items={len(sql_rows)}")
mysql.close()

client = pymongo.MongoClient(
    "mongodb://devbox:devbox@mongodb:27017/?authSource=admin")
db = client["db_l4_07_doc_vs_relational"]
client.drop_database(db.name)
db.orders.insert_one({
    "order_key": "order-A",
    "customer": "customer-A",
    "items": [{"line_no": 1, "sku": "tea"}, {"line_no": 2, "sku": "rice"}],
})
doc = db.orders.find_one({"order_key": "order-A"}, {"_id": 0, "items": 1})
print(f"Mongo embedded document: roundtrips=1 items={len(doc['items'])}")
client.close()
PY
py_file "$script"
