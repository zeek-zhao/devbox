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
grep -qF -e 'tool=grep raw=1 kind=no-match action=use-default' <<<"$out" || {
  echo '[assert] 未命中 grep 未命中翻译行'
  fail=1
}
grep -qF -e 'tool=grep raw=2 kind=tool-broken action=stop' <<<"$out" || {
  echo '[assert] 未命中 grep 工具损坏翻译行'
  fail=1
}
grep -qF -e 'tool=diff raw=1 kind=differ action=write' <<<"$out" || {
  echo '[assert] 未命中 diff 有差异翻译行'
  fail=1
}
n="$(grep -c '^tool=' <<<"$out" || true)"
if [ "$n" -ne 5 ]; then
  echo "[assert] tool= 行数期望 5，实际 $n"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
