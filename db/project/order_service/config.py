"""Connections and namespaced resources for the DB-06 order service."""

import sqlite3

import pymongo
import pymysql
import psycopg2
import redis

MYSQL_DATABASE = "db_db06_orders"
MYSQL_USER = "db06_order_app"
MYSQL_PASSWORD = "devbox_db06"
PG_SCHEMA = "db_db06_reports"
MONGO_DATABASE = "db_db06_audit"
REDIS_PREFIX = "db_db06:"
SQLITE_PATH = "/tmp/db_db06_snapshot.db"
CONFIG_PATH = "/tmp/db_db06_config.db"


def mysql_admin(database=None):
    return pymysql.connect(
        host="mysql", user="root", password="devbox",
        database=database, charset="utf8mb4", autocommit=True,
    )


def mysql_connection():
    return pymysql.connect(
        host="mysql", user=MYSQL_USER, password=MYSQL_PASSWORD,
        database=MYSQL_DATABASE, charset="utf8mb4", autocommit=False,
        cursorclass=pymysql.cursors.DictCursor,
    )


def postgres_connection():
    return psycopg2.connect(
        host="postgres", user="devbox", password="devbox", dbname="devbox",
        application_name="db06_order_service",
    )


def mongo_client():
    return pymongo.MongoClient(
        "mongodb://devbox:devbox@mongodb:27017/?authSource=admin",
        serverSelectionTimeoutMS=5000,
    )


def redis_client():
    return redis.Redis(
        host="redis", password="devbox", decode_responses=True,
        socket_connect_timeout=5, socket_timeout=5,
    )


def sqlite_connection(path=SQLITE_PATH):
    connection = sqlite3.connect(path)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection
