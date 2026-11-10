#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^antipattern id=1 bal=70 id=2 bal=100$' <<<"$out" \
  || { echo "[assert] 未命中反模式半套落库行"; fail=1; }
grep -q '^antipattern sum=170 lost=30 reported=no$' <<<"$out" \
  || { echo "[assert] 未命中反模式吞错汇总行"; fail=1; }
grep -q '^handled err=1264 rollback=yes reported=yes$' <<<"$out" \
  || { echo "[assert] 未命中正路回滚行"; fail=1; }
grep -q '^handled sum=200 lost=0 consistent=yes$' <<<"$out" \
  || { echo "[assert] 未命中正路一致性行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
