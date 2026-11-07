#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'parse branch: parse failed token=<name>' <<<"$out" \
  || { echo "[assert] 未命中派生类 catch 诊断行"; fail=1; }
grep -q 'schema branch: schema failed field=age' <<<"$out" \
  || { echo "[assert] 未命中第二异常类型分发行"; fail=1; }
grep -q 'sliced-free catch: parse failed' <<<"$out" \
  || { echo "[assert] 未命中基类引用虚分发行"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
