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
grep -qF -e 'antipattern=swallow-error bad=exit0 good=exit1' <<<"$out" || {
  echo '[assert] 未命中吞错对照行'
  fail=1
}
grep -qF -e 'antipattern=unquoted-split bad=words=2 good=words=1' <<<"$out" || {
  echo '[assert] 未命中分词对照行'
  fail=1
}
grep -qF -e 'antipattern=pipe-middle-fail bad=exit0 good=exit1' <<<"$out" || {
  echo '[assert] 未命中管道吞错对照行'
  fail=1
}
grep -qF -e 'antipattern=error-on-stdout bad=pipeline-lines=1 good=pipeline-lines=0' <<<"$out" || {
  echo '[assert] 未命中诊断污染管道对照行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
