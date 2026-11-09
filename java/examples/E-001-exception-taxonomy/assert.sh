#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'field age invalid value -1 -> category=VALIDATION action=reject-input' <<<"$out" \
  || { echo "[assert] 未命中 VALIDATION 分类行"; fail=1; }
grep -qF -e 'op fetch-user failed at attempt 2 -> category=TRANSIENT action=retry' <<<"$out" \
  || { echo "[assert] 未命中 TRANSIENT 分类行"; fail=1; }
grep -qF -e 'internal bug in kv-store -> category=INTERNAL action=fail-fast' <<<"$out" \
  || { echo "[assert] 未命中 INTERNAL 分类行"; fail=1; }
grep -qF -e 'taxonomy types=3 VALIDATION=1 TRANSIENT=1 INTERNAL=1' <<<"$out" \
  || { echo "[assert] 未命中分类汇总行"; fail=1; }
n="$(grep -c 'category=' <<<"$out" || true)"
[ "$n" -eq 3 ] || { echo "[assert] category= 行数期望 3，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
