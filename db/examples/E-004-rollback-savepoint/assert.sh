#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^violation err=1062 rollback_to=sp1$' <<<"$out" \
  || { echo "[assert] 未命中 MySQL 约束违反行"; fail=1; }
grep -q '^rows_after_rollback_to=2$' <<<"$out" \
  || { echo "[assert] 未命中保存点部分回滚行"; fail=1; }
grep -q '^pg_after_error err=25P02 class=aborted_txn$' <<<"$out" \
  || { echo "[assert] 未命中 PG 事务中止态行"; fail=1; }
grep -q '^pg_without_savepoint rows_committed=0$' <<<"$out" \
  || { echo "[assert] 未命中 PG 无保存点零提交行"; fail=1; }
grep -q '^pg_with_savepoint rows_committed=2$' <<<"$out" \
  || { echo "[assert] 未命中 PG 保存点存活行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
