#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'attempt 1 failed: TRANSIENT connect-refused' <<<"$out" \
  || { echo "[assert] 未命中第 1 次失败行"; fail=1; }
grep -qF -e 'attempt 2 failed: TRANSIENT connect-refused' <<<"$out" \
  || { echo "[assert] 未命中第 2 次失败行"; fail=1; }
grep -qF -e 'attempt 3 ok: got payload-7' <<<"$out" \
  || { echo "[assert] 未命中成功行"; fail=1; }
grep -qF -e 'backoff: delays=10,20ms -> 2 retries before success' <<<"$out" \
  || { echo "[assert] 未命中退避行"; fail=1; }
grep -qF -e 'no-retry: ValidationException rejected immediately' <<<"$out" \
  || { echo "[assert] 未命中不重试行"; fail=1; }
grep -qF -e 'rule: retry only TRANSIENT errors' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 6 ] || { echo "[assert] 总行数期望 6，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
