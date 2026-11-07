#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'release tx' <<<"$out" || { echo "[assert] 未命中后构造资源先释放行"; fail=1; }
grep -q 'release conn' <<<"$out" || { echo "[assert] 未命中先构造资源后释放行"; fail=1; }
awk '/release tx/{t=NR} /release conn/{c=NR} END{exit !(t>0 && c>0 && t<c)}' <<<"$out" \
  || { echo "[assert] 释放顺序不对：应为 tx 先于 conn（构造逆序）"; fail=1; }
grep -q 'caught: peer reset' <<<"$out" || { echo "[assert] 未命中异常捕获行"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
