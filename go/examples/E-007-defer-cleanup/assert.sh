#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'primary first: write: simulated write failure' <<<"$out" \
  || { echo "[assert] 未命中主错误优先行"; fail=1; }
grep -qF -e 'cleanup visible: cleanup: simulated close failure' <<<"$out" \
  || { echo "[assert] 未命中清理错误可见行"; fail=1; }
grep -qF -e 'all good: err==nil=true closed=true' <<<"$out" \
  || { echo "[assert] 未命中成功关闭行"; fail=1; }
grep -qF -e 'error path cleanup: steps=[open close] err=job failed' <<<"$out" \
  || { echo "[assert] 未命中错误路径清理行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
