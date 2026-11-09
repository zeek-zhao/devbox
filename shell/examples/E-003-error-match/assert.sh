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
grep -qF -e 'rc=1 classified=no-match action=use-default' <<<"$out" || {
  echo '[assert] 未命中未命中->默认值分支'
  fail=1
}
grep -qF -e 'rc=2 classified=probe-broken action=stop' <<<"$out" || {
  echo '[assert] 未命中探针损坏->停止分支'
  fail=1
}
n="$(grep -c '^rc=' <<<"$out" || true)"
if [ "$n" -ne 3 ]; then
  echo "[assert] rc= 行数期望 3，实际 $n"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
