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
grep -qF -e 'antipattern=destructuring bad=1 good=2' <<<"$out" || {
  echo '[assert] 未命中响应性丢失对照行'
  fail=1
}
grep -qF -e 'antipattern=mutate-prop bad=parent=99 good=parent-with-copy=1' <<<"$out" || {
  echo '[assert] 未命中 props 单向数据流对照行'
  fail=1
}
grep -qF -e 'antipattern=swallowed-promise bad=recorded=0 good=recorded=1' <<<"$out" || {
  echo '[assert] 未命中吞错对照行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
