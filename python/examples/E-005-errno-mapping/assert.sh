#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'real-missing: errno=2 type=FileNotFoundError category=MISSING action=create-or-skip' <<<"$out" \
  || { echo "[assert] 未命中真实缺失行"; fail=1; }
grep -qF -e 'denied: errno=13 type=PermissionError category=DENIED action=stop-and-report' <<<"$out" \
  || { echo "[assert] 未命中权限拒绝行"; fail=1; }
grep -qF -e 'transient: errno=11 type=BlockingIOError category=TRANSIENT action=retry' <<<"$out" \
  || { echo "[assert] 未命中可重试行"; fail=1; }
grep -qF -e 'io: errno=5 type=OSError category=UNKNOWN action=fail-fast' <<<"$out" \
  || { echo "[assert] 未命中未知类别行"; fail=1; }
grep -qF -e 'mapping: errno values are the stable interface' <<<"$out" \
  || { echo "[assert] 未命中映射结论行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 5 ] || { echo "[assert] 总行数期望 5，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
