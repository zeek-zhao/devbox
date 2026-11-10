#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^migration_failed err=1072 rollback_done=yes$' <<<"$out" \
  || { echo "[assert] 未命中迁移失败回滚行"; fail=1; }
grep -q '^partial_applied last_login_column=yes$' <<<"$out" \
  || { echo "[assert] 未命中 DDL 残留检测行"; fail=1; }
grep -q '^backfill_committed=0$' <<<"$out" \
  || { echo "[assert] 未命中回填已回滚行"; fail=1; }
grep -q '^rerun backfill_committed=2$' <<<"$out" \
  || { echo "[assert] 未命中幂等重跑补齐行"; fail=1; }
grep -q '^duplicate_column err=1060 handled=idempotent$' <<<"$out" \
  || { echo "[assert] 未命中 1060 幂等处理行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
