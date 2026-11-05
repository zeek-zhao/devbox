#!/usr/bin/env bash
# T-001-asan-heap-overflow 断言：关键诊断行命中 + 退出码符合预期 + 不稳定输出归一化。
# docs/72 §2 样板扩展版：两段断言——最小复现（ASan 路径）与完整演练（valgrind 路径）。
# 用法：bash assert.sh ；连跑两次结论必须一致；退出非零 = 红。
set -uo pipefail
cd "$(dirname "$0")"

fail=0

# ---- 第 1 段：最小复现（ASan 路径）。按 docs/72 真本：故障被触发 = 非零退出码。
out="$(bash repro.sh 2>&1)"; rc=$?
grep -q 'ERROR: AddressSanitizer' <<<"$out" \
  || { echo "[assert] 未命中 ASan 诊断行（ERROR: AddressSanitizer）"; fail=1; }
grep -q 'heap-buffer-overflow' <<<"$out" \
  || { echo "[assert] 未命中 heap-buffer-overflow 类型行"; fail=1; }
[ "$rc" -ne 0 ] || { echo "[assert] 预期非零退出码，实际 0（故障未被触发）"; fail=1; }

# ---- 第 2 段：完整演练（valgrind 路径）。run.sh 内部已做逐步判定，全过 = 退出 0。
tout="$(bash run.sh 2>&1)"; trc=$?
[ "$trc" -eq 0 ] || { echo "[assert] run.sh 应全绿退出 0，实际 $trc"; tail -20 <<<"$tout" >&2; fail=1; }
grep -q 'run: start' <<<"$tout" \
  || { echo "[assert] 未命中执行标记行 run: start（二进制可能未被真正执行，素材 S-06）"; fail=1; }
grep -q 'Invalid write' <<<"$tout" \
  || { echo "[assert] 未命中 valgrind 越界行（Invalid write）"; fail=1; }
grep -q 'definitely lost: 8 bytes in 1 blocks' <<<"$tout" \
  || { echo "[assert] 未命中 valgrind 泄漏统计行（definitely lost: 8 bytes in 1 blocks）"; fail=1; }

# ---- 归一化后复断言：0x 地址 / ==pid== 前缀 → 占位符，禁止逐字比对整段输出。
norm="$(sed -E 's/0x[0-9a-f]+/0xADDR/g; s/==[0-9]+==/==N==/g; s/pid [0-9]+/pid N/g' <<<"$out")"
grep -q 'ERROR: AddressSanitizer: heap-buffer-overflow' <<<"$norm" \
  || { echo "[assert] 归一化后未命中完整 ASan 报告头"; fail=1; }
[ -n "$norm" ] || fail=1

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
