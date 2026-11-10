#!/usr/bin/env bash
# E-009-charset-mojibake · 字符集错配：乱码落库、1366 与 HEX 校验修复
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"

export NS=db_e_E_009_charset_mojibake

if ! tb mysql -h mysql -uroot -N -B -e 'SELECT 1' >/dev/null 2>&1; then
  bash "$DB_ROOT/scripts/up.sh" >/dev/null
  bash "$DB_ROOT/scripts/wait-ready.sh" >/dev/null
fi

cleanup() { mysql_db "DROP DATABASE IF EXISTS $NS" >/dev/null || true; }
trap cleanup EXIT

cleanup
mysql_db "CREATE DATABASE $NS CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
mysql_file "$HERE/schema.sql"

tb python3 - <<'PY'
import pymysql

ns = "db_e_E_009_charset_mojibake"

text = "你好"
good_hex = "E4BDA0E5A5BD"  # text 的 UTF-8 字节，唯一可信的落库指纹


def connect(**kw):
    return pymysql.connect(host="mysql", user="root", password="devbox", **kw)


# ---- 1) 正确路径：连接显式 utf8mb4，写入即得标准字节 ----
good = connect(database=ns, charset="utf8mb4", autocommit=True)
cur = good.cursor()
cur.execute("INSERT INTO msgs (body) VALUES (%s)", (text,))
cur.execute("SELECT HEX(body), CHAR_LENGTH(body) FROM msgs WHERE id = 1")
hx, clen = cur.fetchone()
print(f"utf8_write hex={hx} char_len={clen}")

# ---- 2) 连接声明成 latin1：多字节文本在客户端编码阶段就发不出去 ----
try:
    bad = connect(database=ns, charset="latin1", autocommit=True)
    bad.cursor().execute("INSERT INTO msgs (body) VALUES (%s)", (text,))
    raise SystemExit("expected a client-side encode failure")
except UnicodeEncodeError:
    print("latin1_write client_encode_fail=yes")

# ---- 3) 乱码落库：字节被当成 latin1 转一手，存进去的指纹虽对、读取已坏 ----
mojibake = text.encode("utf-8").decode("latin1")  # 乱码字符串
bad = connect(database=ns, charset="latin1", autocommit=True)
bad.cursor().execute("INSERT INTO msgs (body) VALUES (%s)", (mojibake,))
bad.commit()
bad_cur = bad.cursor()
bad_cur.execute("SELECT HEX(body) FROM msgs WHERE id = 2")
print(f"mojibake_stored hex={bad_cur.fetchone()[0]}")
bad_cur = bad.cursor()
bad_cur.execute("SELECT body, CHAR_LENGTH(body) FROM msgs WHERE id = 2")
body, clen = bad_cur.fetchone()
print(f"mojibake_read body={body!r} char_len={clen}")

# 好 bytes 从坏连接读：服务端把 utf8mb4 降级转成 latin1，'?' 不可逆
bad_cur.execute("SELECT body, CHAR_LENGTH(body) FROM msgs WHERE id = 1")
body, clen = bad_cur.fetchone()
print(f"latin1_read_loss body={body!r} char_len={clen}")

# ---- 4) latin1 列撞上多字节字符：strict 模式直接 1366 ----
try:
    cur.execute("INSERT INTO msgs_latin1 (body) VALUES (%s)", (text,))
    raise SystemExit("expected 1366 for latin1 column")
except pymysql.MySQLError as e:
    print(f"column_latin1 err={e.args[0]} class=charset retryable=no")

# ---- 5) 修复：全链路显式 utf8mb4，以 HEX 为指纹验收 ----
cur.execute("DELETE FROM msgs WHERE id = 2")
cur.execute("SELECT HEX(body) FROM msgs WHERE id = 1")
hx = cur.fetchone()[0]
ok = hx == good_hex
print(f"fixed roundtrip={'yes' if ok else 'no'} hex_match={'yes' if ok else 'no'}")

good.close()
bad.close()
PY
