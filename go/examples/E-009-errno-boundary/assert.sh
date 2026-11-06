#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'boundary text: open /tmp/devbox-e009-missing.conf: no such file or directory' <<<"$out" \
  || { echo "[assert] 未命中标准库诊断行"; fail=1; }
grep -qF -e 'boundary is PathError: true' <<<"$out" \
  || { echo "[assert] 未命中 PathError 提取行"; fail=1; }
grep -qF -e 'boundary code for missing file: 3' <<<"$out" \
  || { echo "[assert] 未命中 NOT_FOUND 错误码行"; fail=1; }
grep -qF -e 'boundary code for bad number: 2' <<<"$out" \
  || { echo "[assert] 未命中 INVALID 错误码行"; fail=1; }
grep -qF -e 'boundary code for success: 0' <<<"$out" \
  || { echo "[assert] 未命中成功码行"; fail=1; }
grep -qF -e 'boundary code for unknown: 70' <<<"$out" \
  || { echo "[assert] 未命中未知兜底码行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
