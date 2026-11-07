#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^flaky attempt=1 code=4 class=retryable backoff_ms=100$' <<<"$out" \
  || { echo "[assert] 未命中第一次退避行（应为 100ms）"; fail=1; }
grep -q '^flaky attempt=3 ok value=42$' <<<"$out" \
  || { echo "[assert] 未命中第三次成功行"; fail=1; }
grep -q '^strict attempt=1 code=1 give_up=1$' <<<"$out" \
  || { echo "[assert] 未命中不可重试立即放弃行"; fail=1; }
grep -q '^flaky attempts_used=3$' <<<"$out" \
  || { echo "[assert] 未命中 flaky 用次汇总行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
