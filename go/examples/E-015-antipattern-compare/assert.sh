#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'antipattern match-by-text: false / correct errors.Is: true' <<<"$out" \
  || { echo "[assert] 未命中文本判定反例对照行"; fail=1; }
grep -qF -e 'antipattern swallow: err==nil=true / correct return: err==nil=false' <<<"$out" \
  || { echo "[assert] 未命中吞错对照行"; fail=1; }
grep -qF -e 'antipattern double-log: mid-layer logs=1 / correct: log once at boundary' <<<"$out" \
  || { echo "[assert] 未命中双记对照行"; fail=1; }
grep -qF -e 'antipattern panic-control: recovered n=0 / correct err=disk full' <<<"$out" \
  || { echo "[assert] 未命中 panic 控制流对照行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
