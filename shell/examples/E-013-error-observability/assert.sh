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
grep -qF -e 'deploy result: ok=3 failed=1' <<<"$out" || {
  echo '[assert] 未命中部署汇总行'
  fail=1
}
grep -qF -e 'step=download status=failed rc=3 reason=network' <<<"$out" || {
  echo '[assert] 未命中 download 失败结构化记录行'
  fail=1
}
n="$(grep -c '^step=' <<<"$out" || true)"
if [ "$n" -ne 4 ]; then
  echo "[assert] step= 结构化记录行期望 4 条，实际 $n"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
