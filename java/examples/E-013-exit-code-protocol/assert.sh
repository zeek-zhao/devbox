#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>/dev/null)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'protocol: usage=2 data=1 success=0' <<<"$out" \
  || { echo "[assert] 未命中协议行"; fail=1; }
grep -qF -e 'rule: map error classes to exit codes once, at the boundary' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
grep -qF -e 'probe-usage-exit: 2' <<<"$out" || { echo "[assert] 未命中 usage 退出码行"; fail=1; }
grep -qF -e 'probe-data-exit: 1' <<<"$out" || { echo "[assert] 未命中 data 退出码行"; fail=1; }
grep -qF -e 'probe-ok-exit: 0' <<<"$out" || { echo "[assert] 未命中 ok 退出码行"; fail=1; }
n="$(grep -c 'probe-.*-exit:' <<<"$out" || true)"
[ "$n" -eq 3 ] || { echo "[assert] 退出码行数期望 3，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
