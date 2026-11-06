#!/usr/bin/env bash
# E-002 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^ok-exit=0$' <<<"$out" \
  || { echo "[assert] 成功路径应记录 ok-exit=0"; fail=1; }
grep -q '^bad-config-exit=1$' <<<"$out" \
  || { echo "[assert] main 返回 Err 应体现为退出码 1"; fail=1; }
grep -q '^Error: ConfigError { field: "workers", source: ParseIntError { kind: InvalidDigit } }$' <<<"$out" \
  || { echo "[assert] 未命中 std 打印的 Error: Debug 诊断行"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
