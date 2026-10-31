#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
from pymongo import MongoClient

NS = "db_l1_mg_04_aggregation"
client = MongoClient("mongodb://devbox:devbox@mongodb:27017/?authSource=admin")
client.drop_database(NS)
db = client[NS]
orders = db.orders
orders.insert_many([
    {"_id": "o1", "customer": "c1", "items": [{"sku": "tea", "qty": 2}, {"sku": "cup", "qty": 1}]},
    {"_id": "o2", "customer": "c2", "items": [{"sku": "tea", "qty": 3}]},
    {"_id": "o3", "customer": "c1", "items": [{"sku": "cup", "qty": 4}]},
])
db.customers.insert_many([
    {"_id": "c1", "name": "Ada"},
    {"_id": "c2", "name": "Lin"},
])
pipeline = [
    {"$match": {"items.qty": {"$gte": 1}}},
    {"$unwind": "$items"},
    {"$lookup": {"from": "customers", "localField": "customer", "foreignField": "_id", "as": "buyer"}},
    {"$unwind": "$buyer"},
    {"$group": {
        "_id": "$items.sku",
        "units": {"$sum": "$items.qty"},
        "orders": {"$addToSet": "$_id"},
        "buyer_names": {"$addToSet": "$buyer.name"},
    }},
    {"$sort": {"_id": 1}},
    {"$project": {"_id": 0, "sku": "$_id", "units": 1, "order_count": {"$size": "$orders"}}},
]
for row in orders.aggregate(pipeline):
    print(f"{row['sku']}\t{row['units']}\t{row['order_count']}")
facet = list(orders.aggregate([
    {"$facet": {
        "order_count": [{"$count": "n"}],
        "customers": [{"$group": {"_id": "$customer"}}, {"$count": "n"}],
    }},
]))[0]
print(f"facet_orders={facet['order_count'][0]['n']}")
print(f"facet_customers={facet['customers'][0]['n']}")
client.close()
PY
)
