"""MongoDB behavior events stored in fixed-day collections."""

from .config import MONGO_DATABASE, mongo_client

COLLECTION = "events_2026_01_01"


class OrderAudit:
    def __init__(self):
        self.client = mongo_client()
        self.database = self.client[MONGO_DATABASE]

    def initialize(self):
        self.client.drop_database(MONGO_DATABASE)
        self.database = self.client[MONGO_DATABASE]
        # L1-MG-01-doc-collection, L1-MG-05-index, L4-07-doc-vs-relational.
        self.database[COLLECTION].create_index(
            [("tenant_key", 1), ("event_seq", 1)], unique=True
        )

    def append(self, event_seq, event_type, tenant_key, order_key):
        # L1-MG-02-crud: event documents evolve independently of normalized order rows.
        collection = self.database[COLLECTION]
        inserted = collection.insert_one(
            {
                "event_seq": event_seq,
                "event_type": event_type,
                "tenant_key": tenant_key,
                "order_key": order_key,
                "event_day": "2026-01-01",
                "metadata": {"source": "order-service", "schema": 1},
            }
        )
        updated = collection.update_one(
            {"_id": inserted.inserted_id},
            {"$set": {"delivery_state": "recorded"}},
        )
        if updated.matched_count != 1:
            raise AssertionError("new audit event could not be marked recorded")

    def summary(self, tenant_key):
        collection = self.database[COLLECTION]
        # L1-MG-03-query-operators: range query uses a stable sequence cursor.
        recent = list(
            collection.find(
                {"tenant_key": tenant_key, "event_seq": {"$gte": 1}},
                {"_id": 0, "event_seq": 1, "event_type": 1},
            ).sort("event_seq", 1)
        )
        # L1-MG-04-aggregation: group documents by behavior type for event counts.
        totals = list(
            collection.aggregate(
                [
                    {"$match": {"tenant_key": tenant_key}},
                    {"$group": {"_id": "$event_type", "count": {"$sum": 1}}},
                    {"$sort": {"_id": 1}},
                ]
            )
        )
        if not recent or sum(row["count"] for row in totals) != len(recent):
            raise AssertionError("audit event aggregation is inconsistent")
        return len(recent), recent[-1]["event_type"]

    def close(self):
        self.client.close()
