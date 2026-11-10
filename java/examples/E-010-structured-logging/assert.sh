#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e '{"code": "TRANSIENT", "level": "ERROR", "message": "db unavailable", "seq": 1}' <<<"$out" \
  || { echo "[assert] 未命中 TRANSIENT 日志行"; fail=1; }
grep -qF -e '{"code": "VALIDATION", "level": "ERROR", "message": "field age must be a positive integer", "seq": 2}' <<<"$out" \
  || { echo "[assert] 未命中 VALIDATION 日志行"; fail=1; }
grep -qF -e '{"code": "NONE", "level": "INFO", "message": "handled 2 errors, service up", "seq": 3}' <<<"$out" \
  || { echo "[assert] 未命中 INFO 日志行"; fail=1; }
grep -qF -e 'rule: one JSON per line' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
n="$(grep -c '^{' <<<"$out" || true)"
[ "$n" -eq 3 ] || { echo "[assert] JSON 行数期望 3，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
