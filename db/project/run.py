"""Run the deterministic DB-06 order-service demonstration."""

from decimal import Decimal

from order_service import audit, cache, order, report, snapshot
from order_service.config import MONGO_DATABASE, REDIS_PREFIX, redis_client

TENANT = "tenant-A"
ORDER_KEY = "O1001"


def main():
    pool = None
    log = audit.OrderAudit()
    cache_service = None
    try:
        pool = order.initialize()
        report.initialize()
        log.initialize()
        cache_service = cache.OrderCache(pool)
        cache_service.initialize()

        print("== 下单")
        created_order_key, created = order.create_order(
            pool, "request-1001", ORDER_KEY, TENANT,
            Decimal("199.00"), "tea-set", 1,
        )
        first_order = order.get_order(pool, ORDER_KEY, TENANT)
        if first_order is None or created_order_key != ORDER_KEY or not created:
            raise AssertionError("order creation did not persist its business key")
        cache_service.register_order(ORDER_KEY, TENANT)
        order.verify_order_index(pool, TENANT)
        # L4-01-order-modeling, L4-02-composite-index, L4-04-idempotency.
        print(
            f"order={first_order['order_key']} amount={first_order['amount']:.2f} "
            f"status={first_order['status']}"
        )
        log.append(1, "ORDER_REQUESTED", TENANT, ORDER_KEY)

        print("== 幂等重放")
        replay_key, replay_created = order.create_order(
            pool, "request-1001", ORDER_KEY, TENANT,
            Decimal("199.00"), "tea-set", 1,
        )
        if replay_created or replay_key != ORDER_KEY:
            raise AssertionError("idempotent replay created a second order")
        log.append(2, "IDEMPOTENCY_REPLAY", TENANT, ORDER_KEY)
        print(f"order={replay_key} (same, idempotent)")

        # L4-05-multi-tenant: scope reads and exports by tenant, not by global order key.
        other_tenant_order, _ = order.create_order(
            pool, "request-2001", "O2001", "tenant-B",
            Decimal("49.00"), "tea-set", 1,
        )
        if order.get_order(pool, other_tenant_order, TENANT) is not None:
            raise AssertionError("cross-tenant order read was not isolated")
        # A second fixed-day fact makes the report's recursive calendar and ranking meaningful.
        order.create_order(
            pool, "request-1002", "O1002", TENANT,
            Decimal("49.00"), "tea-set", 1,
            created_at="2026-01-02 00:00:00",
        )
        # L4-09-soft-delete: deleted rows remain historical but disappear from active reads.
        order.create_order(
            pool, "request-1003", "O1003", TENANT,
            Decimal("1.00"), "sample", 1,
        )
        order.soft_delete_order(pool, "O1003", TENANT)
        active = order.list_order_page(pool, TENANT)
        if [row["order_key"] for row in active] != [ORDER_KEY, "O1002"]:
            raise AssertionError("tenant active-order page included deleted data")
        if order.total_amount(pool, TENANT) != Decimal("248.00"):
            raise AssertionError("MySQL decimal aggregate differs from active orders")
        order.transition_order(pool, ORDER_KEY, TENANT, "PAID")
        try:
            order.transition_order(pool, ORDER_KEY, TENANT, "SHIPPED")
        except ValueError:
            pass
        else:
            raise AssertionError("invalid order state transition was accepted")
        missing, miss_hit = cache_service.get_order("O404", TENANT)
        negative, negative_hit = cache_service.get_order("O404", TENANT)
        if missing is not None or miss_hit or negative is not None or not negative_hit:
            raise AssertionError("Bloom filter and negative cache did not reject a missing key")

        print("== 缓存命中")
        cache_service.add_activity(ORDER_KEY, "ORDER_CREATED")
        cache_service.rank_order(TENANT, ORDER_KEY, first_order["amount"])
        _, warm_hit = cache_service.get_order(ORDER_KEY, TENANT)
        cached, cache_hit = cache_service.get_order(ORDER_KEY, TENANT)
        if warm_hit or not cache_hit or cached["amount"] != "199.00":
            raise AssertionError("cache-aside did not warm then hit the order cache")
        cache_service.invalidate_order(ORDER_KEY, TENANT)
        # L2-05-cache-consistency: the next read misses once and rebuilds from MySQL.
        rebuilt, rebuild_hit = cache_service.get_order(ORDER_KEY, TENANT)
        if rebuild_hit or rebuilt["amount"] != "199.00":
            raise AssertionError("cache invalidation did not trigger a consistent rebuild")
        log.append(3, "ORDER_CREATED", TENANT, ORDER_KEY)
        print(f"cache=HIT amount={cached['amount']}")

        print("== 分布式锁")
        lock_key, token, acquired = cache_service.acquire_lock(ORDER_KEY)
        if not acquired:
            raise AssertionError("order lock was not acquired")
        if cache_service.acquire_lock(ORDER_KEY, "other-owner")[2]:
            raise AssertionError("second lock owner entered a held lock")
        if not cache_service.release_lock(lock_key, token):
            raise AssertionError("lock owner could not release its lock")
        print("lock=ACQUIRED then RELEASED")

        # L2-01-pool-timeout: pool exhaustion is bounded without exhausting MySQL.
        with pool.connection(), pool.connection():
            try:
                with pool.connection():
                    raise AssertionError("full pool unexpectedly lent a connection")
            except order.PoolTimeout:
                pass

        print("== 报表（PG 预聚合）")
        report.refresh_order_report(first_order)
        second_order = order.get_order(pool, "O1002", TENANT)
        if second_order is None:
            raise AssertionError("second report-day order is missing")
        report.refresh_order_report(second_order)
        report.verify_json_index()
        day, count, amount, first_rank = report.daily_total("2026-01-01", TENANT)
        _, second_count, second_amount, second_rank = report.daily_total(
            "2026-01-02", TENANT
        )
        if str(day) != "2026-01-01" or count != 1 or amount != Decimal("199.00"):
            raise AssertionError("PostgreSQL daily report differs from the order source")
        if first_rank != 1 or second_rank != 2 or second_count != 1:
            raise AssertionError("daily report window ranking is inconsistent")
        if second_amount != Decimal("49.00") or len(report.page_order_facts(TENANT)) != 2:
            raise AssertionError("report pagination returned an unexpected order set")
        print(f"day={day} orders={count} amount={amount:.2f}")

        print("== 行为日志（Mongo）")
        event_count, latest = log.summary(TENANT)
        if event_count != 3 or latest != "ORDER_CREATED":
            raise AssertionError("MongoDB behavior event summary is inconsistent")
        print(f"events={event_count} latest={latest}")

        print("== 离线快照（SQLite）")
        snapshot_count = snapshot.initialize(pool)
        if snapshot_count != 1:
            raise AssertionError("SQLite snapshot should contain one active tenant order")
        print(f"snapshot_orders={snapshot_count}")

        # L2-11-metrics: cache hit/miss counters are maintained in namespaced Redis keys.
        metrics = redis_client()
        if int(metrics.get(REDIS_PREFIX + "metrics:cache_hits") or 0) < 1:
            raise AssertionError("cache hit metric was not recorded")
        # L2-15-db-selection: each store owns its natural workload in this service.
        if MONGO_DATABASE != "db_db06_audit":
            raise AssertionError("audit workload database selection changed")
        metrics.close()
    finally:
        if cache_service is not None:
            cache_service.redis.close()
        log.close()
        if pool is not None:
            pool.close()


if __name__ == "__main__":
    main()
