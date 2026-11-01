#!/usr/bin/env bash
# L1-MY-02-crud · 增删改查
# 这是 db 轨道的**参照样板**：其它用例照这个结构写。
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"          # 站在用例自己目录，sql/ 相对路径才对

NS=db_l1_my_02_crud

# 幂等：先清掉自己的命名空间
mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"

echo "== 初始两行"
mysql_file sql/setup.sql
mysql_file sql/query.sql

echo "== UPSERT：id=2 的 qty 从 5 改成 9（不新增行）"
mysql_file sql/upsert.sql
mysql_file sql/query.sql

echo "== DELETE：删掉 id=1"
mysql_file sql/delete.sql
mysql_file sql/query.sql
