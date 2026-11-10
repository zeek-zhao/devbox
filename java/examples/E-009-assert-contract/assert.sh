#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'assert-enabled: true' <<<"$out" \
  || { echo "[assert] 未命中断言开关行（run.sh 必须带 -ea）"; fail=1; }
grep -qF -e 'internal-invariant: AssertionError caught (assertions guard internal bugs)' <<<"$out" \
  || { echo "[assert] 未命中内部不变量行"; fail=1; }
grep -qF -e 'null-contract: NullPointerException: id is required' <<<"$out" \
  || { echo "[assert] 未命中空契约行"; fail=1; }
grep -qF -e 'public-api: IllegalArgumentException: amount must be positive' <<<"$out" \
  || { echo "[assert] 未命中公共契约行"; fail=1; }
grep -qF -e 'rule: assert for internal invariants' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 5 ] || { echo "[assert] 总行数期望 5，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
