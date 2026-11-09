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
grep -qF -e 'sync render error: info=render function' <<<"$out" || {
  echo '[assert] 未命中同步错误通道行'
  fail=1
}
grep -qF -e 'async setup error: info=setup function' <<<"$out" || {
  echo '[assert] 未命中异步 setup 通道行'
  fail=1
}
grep -qF -e 'detached promise error: app-saw=false caught-by-catch=true' <<<"$out" || {
  echo '[assert] 未命中游离 Promise 对照行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
