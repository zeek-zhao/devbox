#!/usr/bin/env bash
# T-001-goroutine-leak 断言：关键诊断行命中 + 退出码符合预期 + 不稳定输出归一化。
# docs/72 §2 样板扩展版：两段断言——最小复现（NumGoroutine 对照路径）与完整演练（race/pprof 路径）。
# 用法：bash assert.sh ；连跑两次结论必须一致；退出非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

# ---- 第 1 段：最小复现（plain 构建 + runtime.NumGoroutine 对照）。
# 按 docs/72 真本：泄漏被坐实 = 非零退出码。
out="$(bash repro.sh 2>&1)"; rc=$?
grep -q 'leak: start' <<<"$out" \
  || { echo "[assert] 未命中执行标记行 leak: start（二进制可能未被真正执行，素材 S-06）"; fail=1; }
grep -Eq 'leak: goroutines before=[0-9]+ after=[0-9]+ delta=[0-9]+' <<<"$out" \
  || { echo "[assert] 未命中 NumGoroutine 对照行（leak: goroutines before=... delta=...）"; fail=1; }
delta="$(sed -nE 's/.*delta=([0-9]+).*/\1/p' <<<"$out" | head -1)"
if [ -z "$delta" ] || [ "$delta" -lt 90 ]; then
  echo "[assert] 泄漏判据 delta>=90 未命中（实际 delta=${delta:-缺失}）"; fail=1
fi
grep -q 'LEAK-CONFIRMED' <<<"$out" \
  || { echo "[assert] 未命中泄漏证据行（LEAK-CONFIRMED: N goroutines still blocked）"; fail=1; }
[ "$rc" -ne 0 ] || { echo "[assert] 预期非零退出码，实际 0（泄漏未被触发）"; fail=1; }

# ---- 第 2 段：完整演练（race / 栈快照 / pprof 路径）。run.sh 内部已做逐步判定，全过 = 退出 0。
tout="$(bash run.sh 2>&1)"; trc=$?
[ "$trc" -eq 0 ] || { echo "[assert] run.sh 应全绿退出 0，实际 $trc"; tail -20 <<<"$tout" >&2; fail=1; }
grep -q 'RUN-PASS' <<<"$tout" \
  || { echo "[assert] 未命中 run.sh 全绿标记（RUN-PASS：5/5）"; fail=1; }
grep -q 'WARNING: DATA RACE' <<<"$tout" \
  || { echo "[assert] 未命中 -race 诊断行（WARNING: DATA RACE）"; fail=1; }
grep -q '\[chan send\]' <<<"$tout" \
  || { echo "[assert] 未命中栈快照停泊状态行（[chan send]）"; fail=1; }
chan="$(sed -nE 's/.*\[chan send\] 停泊状态共 ([0-9]+) 个.*/\1/p' <<<"$tout" | head -1)"
if [ -z "$chan" ] || [ "$chan" -lt 90 ]; then
  echo "[assert] 栈快照 [chan send] 应 >=90 个（实际 ${chan:-缺失}）"; fail=1
fi
cum="$(sed -nE 's/.*main\.handleRequest 累计样本 cum=([0-9]+).*/\1/p' <<<"$tout" | head -1)"
if [ -z "$cum" ] || [ "$cum" -lt 90 ]; then
  echo "[assert] pprof 聚合行 main.handleRequest cum 应 >=90（实际 ${cum:-缺失}）"; fail=1
fi

# ---- 归一化后复断言：0x 地址 / goroutine 编号 / 计数 → 占位符，禁止逐字比对整段输出。
norm="$(sed -E 's/0x[0-9a-f]+/0xADDR/g; s/goroutine [0-9]+/goroutine G/g; s/(before|after|delta)=[0-9]+/\1=N/g; s/LEAK-CONFIRMED: [0-9]+/LEAK-CONFIRMED: N/g' <<<"$out")"
grep -q 'leak: goroutines before=N after=N delta=N' <<<"$norm" \
  || { echo "[assert] 归一化后未命中 NumGoroutine 对照行"; fail=1; }
grep -q 'LEAK-CONFIRMED: N goroutines still blocked' <<<"$norm" \
  || { echo "[assert] 归一化后未命中泄漏证据行"; fail=1; }
[ -n "$norm" ] || fail=1

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
