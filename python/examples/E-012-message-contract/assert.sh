#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e "bad-message: ParseError('oops') (no context: caller guesses)" <<<"$out" \
  || { echo "[assert] 未命中坏消息行"; fail=1; }
grep -qF -e 'contract: bad: field=False value=False action=False' <<<"$out" \
  || { echo "[assert] 未命中坏消息契约行"; fail=1; }
grep -qF -e "good-message: field 'amount' got 'abc' expected integer (act: fix input)" <<<"$out" \
  || { echo "[assert] 未命中好消息行"; fail=1; }
grep -qF -e 'contract: good: field=True value=True action=True' <<<"$out" \
  || { echo "[assert] 未命中好消息契约行"; fail=1; }
grep -qF -e 'rule: messages carry field, value, expectation' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 5 ] || { echo "[assert] 总行数期望 5，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
