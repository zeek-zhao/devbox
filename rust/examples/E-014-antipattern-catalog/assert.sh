#!/usr/bin/env bash
# E-014 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^anti-1 swallowed: true (error cause destroyed by .ok())$' <<<"$out" \
  || { echo "[assert] 未命中吞错反模式取证"; fail=1; }
grep -q '^anti-1 fixed: Err(ParseIntError { kind: InvalidDigit })$' <<<"$out" \
  || { echo "[assert] 未命中吞错修正版输出"; fail=1; }
grep -q '^anti-2 stringly-typed: caller matches on message text only (true)$' \
  <<<"$out" \
  || { echo "[assert] 未命中 stringly-typed 反模式取证"; fail=1; }
grep -q '^anti-2 fixed: variant ConfigError::Port matches by type (true)$' \
  <<<"$out" \
  || { echo "[assert] 未命中 enum 修正版取证"; fail=1; }
grep -q '^anti-3 continue-on-error: total 5 (bad rows silently vanish)$' <<<"$out" \
  || { echo "[assert] 未命中错误后继续跑的失真取证"; fail=1; }
grep -q '^anti-3 fixed: aborted (invalid digit found in string)$' <<<"$out" \
  || { echo "[assert] 未命中整体拒绝修正版输出"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
