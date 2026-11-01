"""SQLite configuration and recoverable offline order snapshots."""

import json
import os
import sqlite3

from .config import CONFIG_PATH, SQLITE_PATH, sqlite_connection
from .order import list_order_page

BACKUP_PATH = "/tmp/db_db06_snapshot-restore.db"
VACUUM_PATH = "/tmp/db_db06_snapshot-vacuum.db"


def initialize(pool):
    for path in (SQLITE_PATH, CONFIG_PATH, BACKUP_PATH, VACUUM_PATH):
        if os.path.exists(path):
            os.remove(path)
    connection = sqlite_connection()
    try:
        # L1-SQ-01-type-affinity, L1-SQ-02-crud, L1-SQ-03-txn-wal.
        # L1-SQ-07-json1: typed columns and JSON payloads preserve local query semantics.
        connection.execute("PRAGMA journal_mode = WAL")
        connection.execute(
            "CREATE TABLE snapshot_orders ("
            "order_key TEXT PRIMARY KEY, tenant_key TEXT NOT NULL,"
            "amount NUMERIC NOT NULL, payload TEXT NOT NULL CHECK(json_valid(payload)))"
        )
        connection.execute(
            "CREATE TABLE snapshot_state (order_count INTEGER NOT NULL)"
        )
        connection.execute("INSERT INTO snapshot_state VALUES (0)")
        # L1-SQ-04-index, L1-SQ-05-view-trigger.
        connection.execute(
            "CREATE INDEX idx_snapshot_tenant_key "
            "ON snapshot_orders(tenant_key, order_key)"
        )
        connection.execute(
            "CREATE VIEW active_snapshot_orders AS "
            "SELECT order_key,tenant_key,amount,payload FROM snapshot_orders"
        )
        connection.execute(
            "CREATE TRIGGER snapshot_order_insert AFTER INSERT ON snapshot_orders "
            "BEGIN UPDATE snapshot_state SET order_count=order_count+1; END"
        )
        # L1-SQ-06-attach: configuration belongs in a separate local database.
        connection.execute("ATTACH DATABASE ? AS local_config", (CONFIG_PATH,))
        connection.execute(
            "CREATE TABLE local_config.settings "
            "(setting_key TEXT PRIMARY KEY, setting_value TEXT NOT NULL)"
        )
        connection.execute(
            "INSERT INTO local_config.settings VALUES ('snapshot_day','2026-01-01')"
        )
        connection.commit()
        connection.execute("DETACH DATABASE local_config")

        # L1-MY-07-import-export: export tenant-scoped MySQL rows into SQLite.
        for row in list_order_page(
            pool, "tenant-A", created_before="2026-01-01 23:59:59"
        ):
            order = _get_full_order(pool, row["order_key"], "tenant-A")
            connection.execute(
                "INSERT INTO snapshot_orders VALUES (?,?,?,?)",
                (
                    order["order_key"], order["tenant_key"], str(order["amount"]),
                    json.dumps({"status": order["status"], "day": "2026-01-01"}),
                ),
            )
        connection.commit()
        count = connection.execute(
            "SELECT order_count FROM snapshot_state"
        ).fetchone()[0]
        json_status = connection.execute(
            "SELECT json_extract(payload,'$.status') "
            "FROM active_snapshot_orders ORDER BY order_key"
        ).fetchall()
        if count != len(json_status):
            raise AssertionError("SQLite snapshot trigger count mismatch")
        # L1-SQ-08-vacuum-backup: VACUUM INTO creates and verifies a compact copy.
        connection.execute("VACUUM INTO ?", (VACUUM_PATH,))
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()

    # L2-07-backup-restore-drill: SQLite's online backup API makes a second restorable copy.
    source = sqlite_connection()
    restored = sqlite3.connect(BACKUP_PATH)
    try:
        source.backup(restored)
        restored.commit()
    finally:
        restored.close()
        source.close()
    check = sqlite3.connect(VACUUM_PATH)
    try:
        if check.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
            raise AssertionError("VACUUM INTO snapshot failed integrity_check")
        if check.execute("SELECT COUNT(*) FROM snapshot_orders").fetchone()[0] != count:
            raise AssertionError("VACUUM INTO snapshot row count mismatch")
    finally:
        check.close()
    restored_check = sqlite3.connect(BACKUP_PATH)
    try:
        if restored_check.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
            raise AssertionError("online backup failed integrity_check")
        if restored_check.execute(
            "SELECT COUNT(*) FROM snapshot_orders"
        ).fetchone()[0] != count:
            raise AssertionError("online backup row count mismatch")
    finally:
        restored_check.close()
    return count


def _get_full_order(pool, order_key, tenant_key):
    from .order import get_order

    row = get_order(pool, order_key, tenant_key)
    if row is None:
        raise LookupError("active order not found for snapshot")
    return row
