"""PostgreSQL daily materialized reports and bounded report reads."""

import json

from .config import PG_SCHEMA, postgres_connection


def initialize():
    connection = postgres_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(f"DROP SCHEMA IF EXISTS {PG_SCHEMA} CASCADE")
            cursor.execute(f"CREATE SCHEMA {PG_SCHEMA}")
            # L1-PG-01-types-jsonb, L1-PG-02-crud, L1-PG-05-index-gin,
            # L1-PG-07-serial-sequence: the generated fact key is internal and never printed.
            cursor.execute(
                f"CREATE TABLE {PG_SCHEMA}.order_facts ("
                "fact_id BIGSERIAL NOT NULL,"
                "report_day DATE NOT NULL,"
                "order_key TEXT NOT NULL,"
                "tenant_key TEXT NOT NULL,"
                "amount NUMERIC(10,2) NOT NULL,"
                "details JSONB NOT NULL,"
                "PRIMARY KEY (report_day,fact_id)) "
                "PARTITION BY RANGE (report_day)"
            )
            cursor.execute(
                f"CREATE TABLE {PG_SCHEMA}.order_facts_2026_q1 "
                f"PARTITION OF {PG_SCHEMA}.order_facts "
                "FOR VALUES FROM ('2026-01-01') TO ('2026-04-01')"
            )
            cursor.execute(
                f"CREATE INDEX order_facts_details_gin ON {PG_SCHEMA}.order_facts "
                "USING GIN (details)"
            )
            cursor.execute(
                f"CREATE MATERIALIZED VIEW {PG_SCHEMA}.daily_totals AS "
                "SELECT report_day, tenant_key, COUNT(*) AS order_count, "
                "ROUND(SUM(amount),2) AS total_amount "
                f"FROM {PG_SCHEMA}.order_facts "
                "GROUP BY report_day, tenant_key"
            )
            connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def refresh_order_report(order):
    connection = postgres_connection()
    try:
        with connection.cursor() as cursor:
            # L1-PG-06-savepoint: isolate report-row insertion in the transaction.
            cursor.execute("SAVEPOINT report_insert")
            cursor.execute(
                f"INSERT INTO {PG_SCHEMA}.order_facts "
                "(report_day,order_key,tenant_key,amount,details) "
                "VALUES (%s,%s,%s,%s,%s::jsonb)",
                (
                    order["created_at"].date(), order["order_key"], order["tenant_key"],
                    order["amount"],
                    json.dumps(
                        {"kind": "order", "status": order["status"], "source": "mysql"}
                    ),
                ),
            )
            cursor.execute("RELEASE SAVEPOINT report_insert")
            cursor.execute(f"REFRESH MATERIALIZED VIEW {PG_SCHEMA}.daily_totals")
            # L4-06-timeseries, L4-10-report-aggregation: roll up fixed-day order facts.
            connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def daily_total(report_day, tenant_key):
    connection = postgres_connection()
    try:
        with connection.cursor() as cursor:
            # L1-PG-03-window: rank daily totals with a stable business-key tiebreaker.
            # L1-PG-04-cte-recursive: generate a date range before joining the aggregate.
            cursor.execute(
                f"WITH RECURSIVE calendar(day) AS ("
                "SELECT %s::date UNION ALL "
                "SELECT day + 1 FROM calendar WHERE day < %s::date"
                "), ranked AS ("
                "SELECT report_day,tenant_key,order_count,total_amount,"
                "ROW_NUMBER() OVER (PARTITION BY tenant_key "
                "ORDER BY total_amount DESC,report_day) AS day_rank "
                f"FROM {PG_SCHEMA}.daily_totals WHERE tenant_key=%s"
                ") SELECT calendar.day,COALESCE(ranked.order_count,0),"
                "COALESCE(ranked.total_amount,0.00),ranked.day_rank "
                "FROM calendar LEFT JOIN ranked ON ranked.report_day=calendar.day "
                "WHERE calendar.day=%s::date AND "
                "EXISTS (SELECT 1 FROM "
                f"{PG_SCHEMA}.order_facts facts WHERE facts.tenant_key=%s "
                "AND facts.report_day=%s::date AND "
                "facts.details @> '{\"kind\":\"order\"}'::jsonb) "
                "ORDER BY calendar.day,ranked.day_rank",
                (
                    "2026-01-01", "2026-01-02", tenant_key, report_day,
                    tenant_key, report_day,
                ),
            )
            row = cursor.fetchone()
            if row is None:
                raise LookupError("report row not found")
            return row
    finally:
        connection.close()


def verify_json_index():
    connection = postgres_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SET enable_seqscan=off")
            cursor.execute(
                f"EXPLAIN SELECT order_key FROM {PG_SCHEMA}.order_facts "
                "WHERE details @> %s::jsonb",
                ('{"kind":"order"}',),
            )
            plan = "\n".join(row[0] for row in cursor.fetchall())
            if "Index" not in plan:
                raise AssertionError("JSONB containment query did not use its GIN index")
    finally:
        connection.close()


def page_order_facts(tenant_key, limit=20):
    # L2-06-batch-pagination: deterministic, bounded report page.
    connection = postgres_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                f"SELECT order_key,report_day FROM {PG_SCHEMA}.order_facts "
                "WHERE tenant_key=%s ORDER BY report_day,order_key LIMIT %s",
                (tenant_key, limit),
            )
            return cursor.fetchall()
    finally:
        connection.close()
