#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'primary failed: primary-db: TRANSIENT primary-db offline' <<<"$out" \
  || { echo "[assert] 未命中主路径失败行"; fail=1; }
grep -qF -e 'fallback: stale-snapshot (served by cache)' <<<"$out" \
  || { echo "[assert] 未命中回退行"; fail=1; }
grep -qF -e 'degradation: failed-sources=1' <<<"$out" \
  || { echo "[assert] 未命中降级统计行"; fail=1; }
grep -qF -e 'no-source: no source available: primary-db: TRANSIENT primary-db offline; archive: PERMANENT archive unreadable' <<<"$out" \
  || { echo "[assert] 未命中全败汇总行"; fail=1; }
grep -qF -e 'rule: degrade with recorded reasons' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 5 ] || { echo "[assert] 总行数期望 5，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
