#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>/dev/null)" # 只断言 stdout：stderr 与 stdout 分离正是本例考点
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'protocol: usage=2 data=1 success=0' <<<"$out" \
  || { echo "[assert] 未命中协议行"; fail=1; }
grep -qF -e 'usage-error -> exit=2' <<<"$out" \
  || { echo "[assert] 未命中用法错误行"; fail=1; }
grep -qF -e 'data-error -> exit=1' <<<"$out" \
  || { echo "[assert] 未命中数据错误行"; fail=1; }
grep -qF -e 'success: limit=10 accepted -> exit=0' <<<"$out" \
  || { echo "[assert] 未命中成功行"; fail=1; }
grep -qF -e 'rule: fail at the boundary with a typed exit code' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 5 ] || { echo "[assert] 总行数期望 5，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
