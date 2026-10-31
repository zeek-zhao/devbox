#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
from pymongo import MongoClient

NS = "db_l1_mg_03_query_operators"
client = MongoClient("mongodb://devbox:devbox@mongodb:27017/?authSource=admin")
client.drop_database(NS)
items = client[NS].items
items.insert_many([
    {"_id": "a", "score": 5, "tags": ["red", "small"], "active": True},
    {"_id": "b", "score": 12, "tags": ["blue", "large"], "active": False},
    {"_id": "c", "score": 20, "tags": ["red", "large"], "active": True},
])
queries = [
    ("comparison", {"score": {"$gte": 12}}),
    ("logical", {"$and": [{"active": True}, {"score": {"$lt": 10}}]}),
    ("exists", {"missing": {"$exists": False}}),
    ("type", {"score": {"$type": "int"}}),
    ("elemMatch", {"tags": {"$elemMatch": {"$eq": "red"}}}),
    ("size", {"tags": {"$size": 2}}),
    ("regex", {"_id": {"$regex": "^a|c$"}}),
]
for label, query in queries:
    print(f"{label}={items.count_documents(query)}")
client.close()
PY
)
