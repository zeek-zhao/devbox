#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'worker: interrupted during sleep' <<<"$out" \
  || { echo "[assert] 未命中中断命中行"; fail=1; }
grep -qF -e 'worker: flag restored=true' <<<"$out" \
  || { echo "[assert] 未命中标志恢复行"; fail=1; }
grep -qF -e 'worker: stopped cooperatively' <<<"$out" \
  || { echo "[assert] 未命中协作停止行"; fail=1; }
grep -qF -e 'main: worker finished, not killed' <<<"$out" \
  || { echo "[assert] 未命中主线程收尾行"; fail=1; }
grep -qF -e 'rule: catching InterruptedException must restore the flag or exit' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
grep -qF -e 'unexpected' <<<"$out" \
  && { echo "[assert] 睡眠完成行不应出现（中断未生效）"; fail=1; } || true
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 5 ] || { echo "[assert] 总行数期望 5，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
