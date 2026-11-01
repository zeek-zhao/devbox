#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
from pymongo import MongoClient

NS = "db_l1_mg_02_crud"
client = MongoClient("mongodb://devbox:devbox@mongodb:27017/?authSource=admin")
client.drop_database(NS)
items = client[NS].items
items.insert_many([
    {"_id": "p1", "name": "apple", "qty": 3},
    {"_id": "p2", "name": "banana", "qty": 5},
])
print(f"count_before={items.count_documents({})}")
items.update_one({"_id": "p2"}, {"$set": {"name": "banana"}, "$inc": {"qty": 4}})
items.replace_one({"_id": "p1"}, {"_id": "p1", "name": "pear", "qty": 7})
items.update_one({"_id": "p3"}, {"$set": {"name": "plum", "qty": 2}}, upsert=True)
print(f"count_after={items.count_documents({})}")
for doc in items.find({}, {"_id": 1, "name": 1, "qty": 1}).sort("_id", 1):
    print(f"{doc['_id']}\t{doc['name']}\t{doc['qty']}")
print(f"deleted={items.delete_many({"_id": {"$in": ["p1", "p3"]}}).deleted_count}")
print(f"count_final={items.count_documents({})}")
client.close()
PY
)
