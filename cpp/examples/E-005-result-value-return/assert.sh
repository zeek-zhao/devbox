#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'miss: error=not found' <<<"$out" || { echo "[assert] 未命中 NotFound 分发行"; fail=1; }
grep -q 'denied: error=permissions denied' <<<"$out" || { echo "[assert] 未命中 Permissions 分发行"; fail=1; }
grep -q 'optional: value_or=7' <<<"$out" || { echo "[assert] 未命中 optional value_or 行"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
