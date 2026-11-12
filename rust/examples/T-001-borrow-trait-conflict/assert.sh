#!/usr/bin/env bash
# T-001-borrow-trait-conflict 断言：关键诊断行命中 + 退出码符合预期 + 不稳定输出归一化。
# docs/72 §2 样板扩展版：两段断言——最小复现（rustc 路径）与完整演练（cargo/修复路径）。
# 用法：bash assert.sh ；连跑两次结论必须一致；退出非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

# ---- 第 1 段：最小复现（rustc 路径）。按 docs/72 真本：故障被触发 = 非零退出码。
out="$(bash repro.sh 2>&1)"
rc=$?
grep -q 'E0119' <<<"$out" \
  || { echo "[assert] 未命中特征冲突错误码（E0119）"; fail=1; }
grep -q 'conflicting implementations' <<<"$out" \
  || { echo "[assert] 未命中特征冲突诊断行（conflicting implementations）"; fail=1; }
[ "$rc" -ne 0 ] || { echo "[assert] 预期非零退出码，实际 0（故障未被触发）"; fail=1; }

# ---- 第 2 段：完整演练（cargo/修复路径）。run.sh 内部已做逐步判定，全过 = 退出 0。
tout="$(bash run.sh 2>&1)"
trc=$?
[ "$trc" -eq 0 ] || { echo "[assert] run.sh 应全绿退出 0，实际 $trc"; tail -20 <<<"$tout" >&2; fail=1; }
grep -q 'run: start' <<<"$tout" \
  || { echo "[assert] 未命中执行标记行 run: start（二进制可能未被真正执行，素材 S-06）"; fail=1; }
grep -q 'E0502' <<<"$tout" \
  || { echo "[assert] 未命中借用检查错误码（E0502，应在 step 3 浮出）"; fail=1; }
grep -q 'immutable borrow occurs here' <<<"$tout" \
  || { echo "[assert] 未命中三段标注第二段（immutable borrow occurs here）"; fail=1; }
grep -q 'immutable borrow later used here' <<<"$tout" \
  || { echo "[assert] 未命中三段标注第三段（immutable borrow later used here）"; fail=1; }
grep -q 'first=90 total=4' <<<"$tout" \
  || { echo "[assert] 未命中修复版健康输出（first=90 total=4）"; fail=1; }
grep -q '字符串: 你好' <<<"$tout" \
  || { echo "[assert] 未命中修复版特征分发输出（字符串: 你好）"; fail=1; }

# ---- 归一化后复断言：0x 地址 → 占位符，禁止逐字比对整段输出。
norm="$(sed -E 's/0x[0-9a-fA-F]+/0xADDR/g' <<<"$out")"
grep -q 'error\[E0119\]: conflicting implementations of trait' <<<"$norm" \
  || { echo "[assert] 归一化后未命中完整 E0119 报告头"; fail=1; }
[ -n "$norm" ] || fail=1

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
