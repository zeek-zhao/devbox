"""Transactional MySQL order writes and tenant-scoped reads."""

from contextlib import contextmanager
from queue import Empty, Full, Queue

from .config import (
    MYSQL_DATABASE,
    MYSQL_PASSWORD,
    MYSQL_USER,
    mysql_admin,
    mysql_connection,
)


class PoolTimeout(TimeoutError):
    """Raised when the bounded application pool has no free connection."""


class ConnectionPool:
    # L2-01-pool-timeout: bound application concurrency independently of server limits.
    def __init__(self, size=2, timeout=0.1):
        self._connections = Queue(maxsize=size)
        self._timeout = timeout
        try:
            for _ in range(size):
                self._connections.put_nowait(mysql_connection())
        except Exception:
            self.close()
            raise

    @contextmanager
    def connection(self):
        try:
            connection = self._connections.get(timeout=self._timeout)
        except Empty as exc:
            raise PoolTimeout("order connection pool exhausted") from exc
        try:
            yield connection
        finally:
            connection.rollback()
            try:
                self._connections.put_nowait(connection)
            except Full:
                connection.close()

    def close(self):
        while True:
            try:
                self._connections.get_nowait().close()
            except Empty:
                break


def initialize():
    admin = mysql_admin()
    try:
        with admin.cursor() as cursor:
            cursor.execute(f"DROP DATABASE IF EXISTS {MYSQL_DATABASE}")
            cursor.execute(
                f"CREATE DATABASE {MYSQL_DATABASE} "
                "CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
            )
            cursor.execute(f"DROP USER IF EXISTS '{MYSQL_USER}'@'%'")
            cursor.execute(
                f"CREATE USER '{MYSQL_USER}'@'%' IDENTIFIED BY '{MYSQL_PASSWORD}'"
            )
            cursor.execute(
                f"GRANT SELECT, INSERT, UPDATE, DELETE ON {MYSQL_DATABASE}.* "
                f"TO '{MYSQL_USER}'@'%'"
            )
    finally:
        admin.close()

    connection = mysql_admin(MYSQL_DATABASE)
    try:
        with connection.cursor() as cursor:
            # L1-MY-01-create-and-types, L1-MY-02-crud, L1-MY-04-index-explain,
            # L1-MY-06-user-grant, L2-08-schema-migration, L2-09-least-privilege,
            # L2-12-data-integrity, L4-01-order-modeling, L4-02-composite-index,
            # L4-04-idempotency, L4-05-multi-tenant, L4-09-soft-delete.
            cursor.execute(
                "CREATE TABLE schema_migrations ("
                "version INT PRIMARY KEY, applied_on DATE NOT NULL)"
            )
            cursor.execute(
                "CREATE TABLE orders ("
                "order_key VARCHAR(24) PRIMARY KEY,"
                "tenant_key VARCHAR(24) NOT NULL,"
                "status ENUM('CREATED','PAID','CANCELLED') NOT NULL,"
                "amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),"
                "deleted_at DATE NULL,"
                "created_at DATETIME NOT NULL,"
                "UNIQUE KEY uq_order_tenant (tenant_key, order_key),"
                "KEY idx_orders_tenant_active_key "
                "(tenant_key, deleted_at, order_key))"
            )
            cursor.execute(
                "CREATE TABLE order_items ("
                "order_key VARCHAR(24) NOT NULL,"
                "line_no SMALLINT NOT NULL,"
                "sku VARCHAR(32) NOT NULL,"
                "quantity INT NOT NULL CHECK (quantity > 0),"
                "unit_price DECIMAL(10,2) NOT NULL,"
                "PRIMARY KEY (order_key, line_no),"
                "CONSTRAINT fk_items_order FOREIGN KEY (order_key) "
                "REFERENCES orders(order_key))"
            )
            cursor.execute(
                "CREATE TABLE idempotency_records ("
                "request_key VARCHAR(40) PRIMARY KEY,"
                "request_payload VARCHAR(80) NOT NULL,"
                "order_key VARCHAR(24) NULL UNIQUE)"
            )
            # L2-08-schema-migration: record the schema version after DDL succeeds.
            cursor.execute(
                "INSERT INTO schema_migrations VALUES (1, '2026-01-01')"
            )
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()
    return ConnectionPool()


def create_order(
    pool, request_key, order_key, tenant_key, amount, sku, quantity,
    created_at="2026-01-01 00:00:00",
):
    request_payload = f"{tenant_key}|{amount:.2f}|{sku}|{quantity}|{created_at}"
    with pool.connection() as connection:
        try:
            with connection.cursor() as cursor:
                # L1-MY-05-transaction: order header, item, and idempotency record commit together.
                cursor.execute(
                    "INSERT IGNORE INTO idempotency_records "
                    "(request_key, request_payload) VALUES (%s,%s)",
                    (request_key, request_payload),
                )
                created = cursor.rowcount == 1
                cursor.execute(
                    "SELECT request_payload, order_key FROM idempotency_records "
                    "WHERE request_key=%s FOR UPDATE",
                    (request_key,),
                )
                record = cursor.fetchone()
                if record["request_payload"] != request_payload:
                    raise ValueError("idempotency key reused with a different payload")
                if created:
                    cursor.execute(
                        "INSERT INTO orders "
                        "(order_key,tenant_key,status,amount,deleted_at,created_at) "
                        "VALUES (%s,%s,'CREATED',%s,NULL,%s)",
                        (order_key, tenant_key, amount, created_at),
                    )
                    cursor.execute(
                        "INSERT INTO order_items "
                        "(order_key,line_no,sku,quantity,unit_price) VALUES (%s,1,%s,%s,%s)",
                        (order_key, sku, quantity, amount),
                    )
                    cursor.execute(
                        "UPDATE idempotency_records SET order_key=%s WHERE request_key=%s",
                        (order_key, request_key),
                    )
                connection.commit()
                return (order_key if created else record["order_key"]), created
        except Exception:
            connection.rollback()
            raise


def get_order(pool, order_key, tenant_key):
    with pool.connection() as connection, connection.cursor() as cursor:
        # L1-MY-03-join-group: join the order header to its durable item snapshot.
        cursor.execute(
            "SELECT o.order_key,o.tenant_key,o.status,o.amount,o.created_at,"
            "i.sku,i.quantity,i.unit_price "
            "FROM orders o JOIN order_items i ON i.order_key=o.order_key "
            "WHERE o.order_key=%s AND o.tenant_key=%s AND o.deleted_at IS NULL "
            "ORDER BY i.line_no",
            (order_key, tenant_key),
        )
        return cursor.fetchone()


def list_order_page(pool, tenant_key, after_key="", limit=20, created_before=None):
    # L2-06-batch-pagination: keyset pagination keeps ordering stable across pages.
    with pool.connection() as connection, connection.cursor() as cursor:
        date_filter = " AND created_at<=%s" if created_before else ""
        cursor.execute(
            "SELECT order_key,amount,status,created_at FROM orders "
            "WHERE tenant_key=%s AND deleted_at IS NULL AND order_key>%s"
            + date_filter
            + " "
            "ORDER BY order_key LIMIT %s",
            (
                (tenant_key, after_key, created_before, limit)
                if created_before else (tenant_key, after_key, limit)
            ),
        )
        return cursor.fetchall()


def transition_order(pool, order_key, tenant_key, new_status):
    # L4-01-order-modeling: only declared state-machine edges may change status.
    allowed = {"CREATED": {"PAID", "CANCELLED"}, "PAID": set(), "CANCELLED": set()}
    with pool.connection() as connection:
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT status FROM orders WHERE order_key=%s AND tenant_key=%s "
                    "AND deleted_at IS NULL FOR UPDATE",
                    (order_key, tenant_key),
                )
                row = cursor.fetchone()
                if row is None or new_status not in allowed[row["status"]]:
                    raise ValueError("invalid order status transition")
                cursor.execute(
                    "UPDATE orders SET status=%s WHERE order_key=%s AND tenant_key=%s",
                    (new_status, order_key, tenant_key),
                )
            connection.commit()
        except Exception:
            connection.rollback()
            raise


def soft_delete_order(pool, order_key, tenant_key):
    with pool.connection() as connection:
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    "UPDATE orders SET deleted_at='2026-01-01' "
                    "WHERE order_key=%s AND tenant_key=%s AND deleted_at IS NULL",
                    (order_key, tenant_key),
                )
            connection.commit()
        except Exception:
            connection.rollback()
            raise


def verify_order_index(pool, tenant_key):
    with pool.connection() as connection, connection.cursor() as cursor:
        cursor.execute(
            "EXPLAIN SELECT order_key FROM orders "
            "FORCE INDEX (idx_orders_tenant_active_key) "
            "WHERE tenant_key=%s AND deleted_at IS NULL ORDER BY order_key",
            (tenant_key,),
        )
        plan = cursor.fetchone()
        if plan["key"] != "idx_orders_tenant_active_key":
            raise AssertionError("tenant order query did not use its composite index")


def total_amount(pool, tenant_key):
    with pool.connection() as connection, connection.cursor() as cursor:
        # L1-MY-08-functions: ROUND keeps decimal output deterministic.
        cursor.execute(
            "SELECT ROUND(COALESCE(SUM(amount),0),2) AS total "
            "FROM orders WHERE tenant_key=%s AND deleted_at IS NULL",
            (tenant_key,),
        )
        return cursor.fetchone()["total"]
