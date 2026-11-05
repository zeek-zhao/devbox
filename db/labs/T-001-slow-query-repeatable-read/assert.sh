#!/usr/bin/env bash
# T-001-slow-query-repeatable-read 断言：关键诊断行命中 + 退出码符合预期 + 不稳定输出归一化。
# docs/72 §2 样板扩展版：两段断言——最小复现（repro.sh，退出码 1 = 证据坐实）
# 与完整演练（run.sh 全绿退出 0）。用法：bash assert.sh；连跑两次结论必须一致。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

# ---- 第 1 段：最小复现（EXPLAIN/Handler 全表扫 + 快照读）。
out="$(bash repro.sh 2>&1)"
rc=$?
grep -q 'EXPLAIN-SCAN: type=ALL key=NULL' <<<"$out" ||
  {
    echo "[assert] 未命中全表扫执行计划行（EXPLAIN-SCAN: type=ALL key=NULL）"
    fail=1
  }
scan_rows="$(sed -nE 's/.*EXPLAIN-SCAN: type=ALL key=NULL rows=([0-9]+).*/\1/p' <<<"$out" | head -1)"
if [ -z "$scan_rows" ] || [ "$scan_rows" -lt 10000 ]; then
  echo "[assert] 全表扫 rows 应 >=10000（实际 ${scan_rows:-缺失}）"
  fail=1
fi
grep -q 'HANDLER-SCAN: read_rnd_next=' <<<"$out" ||
  {
    echo "[assert] 未命中全表扫 Handler 计数行（HANDLER-SCAN: read_rnd_next=...）"
    fail=1
  }
scan_rnd="$(sed -nE 's/.*HANDLER-SCAN: read_rnd_next=([0-9]+).*/\1/p' <<<"$out" | head -1)"
if [ -z "$scan_rnd" ] || [ "$scan_rnd" -lt 10000 ]; then
  echo "[assert] 全表扫 Handler_read_rnd_next 应 >=10000（实际 ${scan_rnd:-缺失}）"
  fail=1
fi
grep -q 'first_read=1' <<<"$out" ||
  {
    echo "[assert] 未命中快照首读行（first_read=1）"
    fail=1
  }
grep -q 'second_read=1' <<<"$out" ||
  {
    echo "[assert] 未命中快照复读行（second_read=1，B 已提交插入却仍读旧值）"
    fail=1
  }
grep -q 'fresh_read=2' <<<"$out" ||
  {
    echo "[assert] 未命中新连接对照行（fresh_read=2）"
    fail=1
  }
[ "$rc" -ne 0 ] ||
  {
    echo "[assert] repro.sh 预期非零退出码（证据坐实纪律），实际 0"
    fail=1
  }

# ---- 第 2 段：完整演练（run.sh 内部已做逐步判定，全过 = 退出 0）。
tout="$(bash run.sh 2>&1)"
trc=$?
[ "$trc" -eq 0 ] || {
  echo "[assert] run.sh 应全绿退出 0，实际 $trc"
  tail -20 <<<"$tout" >&2
  fail=1
}
grep -q 'RUN-PASS' <<<"$tout" ||
  {
    echo "[assert] 未命中 run.sh 全绿标记（RUN-PASS：5/5）"
    fail=1
  }
grep -q 'EXPLAIN-IDX: type=ref key=idx_val' <<<"$tout" ||
  {
    echo "[assert] 未命中加索引后执行计划行（EXPLAIN-IDX: type=ref key=idx_val）"
    fail=1
  }
idx_rows="$(sed -nE 's/.*EXPLAIN-IDX: type=ref key=idx_val rows=([0-9]+).*/\1/p' <<<"$tout" | head -1)"
if [ -z "$idx_rows" ] || [ "$idx_rows" -gt 10 ]; then
  echo "[assert] 加索引后 rows 应 <=10（实际 ${idx_rows:-缺失}）"
  fail=1
fi
grep -q 'HANDLER-IDX: read_rnd_next=0' <<<"$tout" ||
  {
    echo "[assert] 未命中加索引后 Handler 归零行（HANDLER-IDX: read_rnd_next=0）"
    fail=1
  }
grep -q 'tx_isolation=REPEATABLE-READ' <<<"$tout" ||
  {
    echo "[assert] 未命中隔离级别行（tx_isolation=REPEATABLE-READ）"
    fail=1
  }

# ---- 归一化后复断言：rows 统计估计 / 计数值 → 占位符，禁止逐字比对整段输出。
norm="$(sed -E 's/rows=[0-9]+/rows=N/g; s/read_rnd_next=[0-9]+/read_rnd_next=N/g' <<<"$out")"
grep -q 'EXPLAIN-SCAN: type=ALL key=NULL rows=N' <<<"$norm" ||
  {
    echo "[assert] 归一化后未命中全表扫计划行"
    fail=1
  }
grep -q 'HANDLER-SCAN: read_rnd_next=N' <<<"$norm" ||
  {
    echo "[assert] 归一化后未命中全表扫计数行"
    fail=1
  }
[ -n "$norm" ] || fail=1

if [ "$fail" -eq 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
