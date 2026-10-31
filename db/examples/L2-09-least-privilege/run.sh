#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

db=db_l2_09_least_privilege
user=l2_09_app
mysql_db "DROP DATABASE IF EXISTS $db; DROP USER IF EXISTS '$user'@'%'; CREATE DATABASE $db; CREATE USER '$user'@'%' IDENTIFIED BY 'app-pass'; CREATE TABLE $db.items (name VARCHAR(32) PRIMARY KEY, qty INT NOT NULL); GRANT SELECT, INSERT, UPDATE, DELETE ON $db.* TO '$user'@'%';"
tb mysql -h mysql -u"$user" -papp-pass -N -B "$db" -e "INSERT INTO items VALUES ('widget', 2); UPDATE items SET qty=qty+1 WHERE name='widget'; SELECT name, qty FROM items ORDER BY name;"
err="$(mktemp)"
if tb mysql -h mysql -u"$user" -papp-pass -N -B "$db" -e 'DROP TABLE items' >/dev/null 2>"$err"; then
  rm -f "$err"
  die "应用账号意外获得 DROP 权限"
fi
if ! grep -q 'ERROR 1142' "$err"; then
  cat "$err" >&2
  rm -f "$err"
  die "拒绝 DDL 的错误码不是 MySQL 1142"
fi
rm -f "$err"
echo "DROP denied: 1142"
