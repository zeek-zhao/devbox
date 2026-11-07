#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'fail-fast: config: workers must be positive' <<<"$out" \
  || { echo "[assert] 未命中入口拒绝诊断行"; fail=1; }
grep -q 'cleanup: release 0 items' <<<"$out" \
  || { echo "[assert] 未命中零副作用证据行（fail-fast 应发生在占资源前）"; fail=1; }
grep -q 'cleanup: release 2 items' <<<"$out" \
  || { echo "[assert] 未命中正常路径资源释放行"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
