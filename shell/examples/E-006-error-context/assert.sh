#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
if [ "$rc" -ne 0 ]; then
  echo "[assert] run.sh 退出码非 0：rc=$rc"
  fail=1
fi
grep -qF -e 'context chain: deploy: download: fetch: connection refused (rc=7)' <<<"$out" || {
  echo '[assert] 未命中完整上下文链行'
  fail=1
}
grep -qF -e 'chain layers: 3' <<<"$out" || {
  echo '[assert] 未命中链层数行'
  fail=1
}
grep -qF -e 'fetch: connection refused' <<<"$out" || {
  echo '[assert] 未命中底层技术原因行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
