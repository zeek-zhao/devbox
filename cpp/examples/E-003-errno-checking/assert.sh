#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'fopen missing: errno=2 (No such file or directory)' <<<"$out" \
  || { echo "[assert] 未命中 errno 诊断行"; fail=1; }
grep -q 'after success call errno still reports: No such file or directory' <<<"$out" \
  || { echo "[assert] 未命中 errno 残留现象行"; fail=1; }
grep -q 'system_error: code=2' <<<"$out" \
  || { echo "[assert] 未命中 system_error 码行"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
