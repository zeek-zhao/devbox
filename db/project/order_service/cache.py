"""Redis cache-aside, single-flight locking, and order ranking."""

import hashlib
import time

from .config import REDIS_PREFIX, redis_client

_RELEASE_LOCK = """
if redis.call('GET', KEYS[1]) == ARGV[1] then
  return redis.call('DEL', KEYS[1])
end
return 0
"""


class OrderCache:
    def __init__(self, pool):
        self.redis = redis_client()
        self.pool = pool

    def initialize(self):
        # L1-RD-01-key-ops: only this project's ID-derived Redis key prefix is cleared.
        for key in self.redis.scan_iter(match=REDIS_PREFIX + "*"):
            self.redis.unlink(key)

    def acquire_lock(self, order_key, token="db06-owner"):
        # L3-08-distributed-lock: SET NX EX is atomic; the Lua release checks ownership.
        lock_key = REDIS_PREFIX + "lock:" + order_key
        acquired = self.redis.set(lock_key, token, nx=True, ex=10)
        return lock_key, token, bool(acquired)

    def register_order(self, order_key, tenant_key):
        digest = hashlib.sha256(f"{tenant_key}:{order_key}".encode()).digest()
        positions = [
            int.from_bytes(digest[:4], "big") % (1 << 20),
            int.from_bytes(digest[4:8], "big") % (1 << 20),
        ]
        bloom_key = REDIS_PREFIX + "bloom:orders"
        for position in positions:
            self.redis.setbit(bloom_key, position, 1)

    def _might_exist(self, order_key, tenant_key):
        digest = hashlib.sha256(f"{tenant_key}:{order_key}".encode()).digest()
        positions = (
            int.from_bytes(digest[:4], "big") % (1 << 20),
            int.from_bytes(digest[4:8], "big") % (1 << 20),
        )
        bloom_key = REDIS_PREFIX + "bloom:orders"
        return all(self.redis.getbit(bloom_key, position) for position in positions)

    def release_lock(self, lock_key, token):
        return self.redis.eval(_RELEASE_LOCK, 1, lock_key, token) == 1

    def get_order(self, order_key, tenant_key):
        # L4-03-cache-pattern: load through MySQL on a miss, then serve Redis on later reads.
        cache_key = REDIS_PREFIX + "order:" + tenant_key + ":" + order_key
        negative_key = cache_key + ":negative"
        cached = self.redis.hgetall(cache_key)
        if cached:
            # L1-RD-04-hash, L1-RD-02-string, L1-RD-06-expire-evict.
            self.redis.incr(REDIS_PREFIX + "metrics:cache_hits")
            return cached, True

        # L3-09-cache-breakdown: Bloom rejection and short negative caching limit penetration.
        if not self._might_exist(order_key, tenant_key):
            if self.redis.get(negative_key):
                self.redis.incr(REDIS_PREFIX + "metrics:negative_hits")
                return None, True
            self.redis.set(negative_key, "1", ex=5)
            self.redis.incr(REDIS_PREFIX + "metrics:bloom_rejections")
            return None, False

        # L3-09-cache-breakdown: one owner rebuilds a cold hot-key cache entry.
        lock_key, token, acquired = self.acquire_lock("cache:" + cache_key)
        if not acquired:
            for _ in range(50):
                time.sleep(0.01)
                cached = self.redis.hgetall(cache_key)
                if cached:
                    return cached, True
            raise TimeoutError("timed out waiting for the cache rebuild lock")
        try:
            cached = self.redis.hgetall(cache_key)
            if cached:
                return cached, True
            row = self._load_order(order_key, tenant_key)
            if row is None:
                self.redis.set(negative_key, "1", ex=5)
                return None, False
            value = {
                "order_key": row["order_key"],
                "tenant_key": row["tenant_key"],
                "status": row["status"],
                "amount": f"{row['amount']:.2f}",
                "sku": row["sku"],
                "quantity": str(row["quantity"]),
            }
            # L1-RD-07-multi-exec: cache hash, expiry, and metrics commit atomically.
            with self.redis.pipeline(transaction=True) as pipe:
                pipe.hset(cache_key, mapping=value)
                ttl = 240 + sum(map(ord, order_key)) % 121
                pipe.expire(cache_key, ttl)
                pipe.incr(REDIS_PREFIX + "metrics:cache_misses")
                pipe.execute()
            return value, False
        finally:
            if acquired:
                self.release_lock(lock_key, token)

    def _load_order(self, order_key, tenant_key):
        row = self._fetch_order(order_key, tenant_key)
        return row

    def _fetch_order(self, order_key, tenant_key):
        from .order import get_order

        return get_order(self.pool, order_key, tenant_key)

    def invalidate_order(self, order_key, tenant_key):
        # L2-05-cache-consistency: an order update invalidates its tenant-scoped cache.
        self.redis.delete(REDIS_PREFIX + "order:" + tenant_key + ":" + order_key)

    def add_activity(self, order_key, activity):
        # L1-RD-03-list: maintain a bounded per-order activity stream.
        key = REDIS_PREFIX + "activity:" + order_key
        self.redis.rpush(key, activity)
        self.redis.ltrim(key, -20, -1)

    def rank_order(self, tenant_key, order_key, amount):
        # L1-RD-05-set-zset, L4-08-counter-ranking: rank orders by amount per tenant.
        self.redis.zadd(
            REDIS_PREFIX + "ranking:" + tenant_key, {order_key: float(amount)}
        )
