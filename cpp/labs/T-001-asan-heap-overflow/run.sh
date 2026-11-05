#!/usr/bin/env bash
# T-001-asan-heap-overflow 演练入口：裸跑 → ASan → valgrind → gdb batch，四步串完整流程。
# 工具（g++ / valgrind / gdb）预装在 devbox-cpp 镜像里（cpp/docs/工具指南.md §1），
# 请在容器内运行，例如：
#   docker run --rm -v "$PWD":/work -w /work \
#     ghcr.io/zeek-zhao/devbox-cpp:latest bash cpp/labs/T-001-asan-heap-overflow/run.sh
# 产物只写临时目录，不入库。用法：bash run.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

CXX="${CXX:-g++}"
BUILD="${TMPDIR:-/tmp}/devbox-cpp-T-001-asan-heap-overflow"
PLAIN="$BUILD/buggy-plain"
ASAN="$BUILD/buggy-asan"
mkdir -p "$BUILD"
# 输出归一化：0x 地址与 ==pid== 前缀在两次运行间必然不同，展示前先打成占位符（docs/72 §2）。
norm() { sed -E 's/0x[0-9a-f]+/0xADDR/g; s/==[0-9]+==/==N==/g'; }

FLAGS="-std=c++20 -Wall -Wextra -pedantic -g -O0 -fno-omit-frame-pointer"
pass=0
step() { echo; echo "=== [step $1] $2 ==="; }
ok()  { echo "  -> 符合预期"; pass=$((pass+1)); }
bad() { echo "  -> 不符合预期：$1" >&2; }

step 1 "裸跑（无工具构建）：越界静默通过，肉眼不可见"
"$CXX" $FLAGS main.cpp -o "$PLAIN" || { echo "编译失败" >&2; exit 2; }
out="$("$PLAIN" 2>&1)"; rc=$?
echo "$out"
if [ "$rc" -eq 0 ] && grep -q 'run: start' <<<"$out" && grep -q 'sum=45' <<<"$out"; then
  ok
  echo "  (退出码 0 + 标记行 run: start / sum=45 正常打印，证明二进制真的被执行过（素材 S-06 分支），"
  echo "   而缺陷完全静默——症状不可靠，必须靠工具。注意：裸跑结局取决于 glibc 堆布局，"
  echo "   同一份代码只要改动一次堆分配顺序（如在 new[] 前多打一行），就可能死于下游 malloc 断言，"
  echo "   见 WALKTHROUGH 的 POE 点)"
else
  bad "裸跑应退出 0 且打印 run: start / sum=45；若标记行缺失，先怀疑二进制未真正执行（S-06），再谈代码"
fi

step 2 "ASan 构建：精确定位越界写"
"$CXX" $FLAGS -fsanitize=address main.cpp -o "$ASAN" || { echo "编译失败" >&2; exit 2; }
alog="$BUILD/asan.log"
if "$ASAN" >"$alog" 2>&1; then
  bad "ASan 构建竟退出 0，越界未被捕获"
else
  arc=$?
  ok
  echo "  (ASan 退出码 $arc；报告头与关键行（已归一化）如下)"
  grep -E 'ERROR: AddressSanitizer|WRITE of size|allocated by thread|#0 |#1 |#2 |SUMMARY' \
    "$alog" | head -10 | norm | sed 's/^/  | /'
fi

step 3 "valgrind（跑无工具构建）：越界 + 泄漏一并现形"
vlog="$BUILD/valgrind.log"
valgrind --leak-check=full --error-exitcode=42 "$PLAIN" >"$vlog" 2>&1
vrc=$?
grep -E 'Invalid write|definitely lost|LEAK SUMMARY|total heap usage' \
  "$vlog" | norm | sed 's/^/  | /'
if [ "$vrc" -eq 42 ]; then
  ok
else
  bad "valgrind 应以 --error-exitcode=42 退出，实际 $vrc"
fi

step 4 "gdb batch（跑 ASan 构建）：在故障现场取调用栈"
glog="$BUILD/gdb.log"
# abort_on_error=1 让 ASan 以 SIGABRT 停下，gdb 才能接到现场打 bt（默认行为是直接 exit 1）。
ASAN_OPTIONS=abort_on_error=1:detect_leaks=0 \
  gdb -batch -ex run -ex bt --args "$ASAN" >"$glog" 2>&1 || true
grep -E 'heap-buffer-overflow|main.cpp:' "$glog" | head -8 | norm | sed 's/^/  | /'
if grep -q 'heap-buffer-overflow' "$glog" && grep -q 'main.cpp:' "$glog"; then
  ok
  echo "  (gdb 回溯给出 main.cpp:<行号>，与 ASan 报告的故障行互证)"
else
  bad "gdb 输出中未见 ASan 报告或 main.cpp 行号"
fi

echo
if [ "$pass" -eq 4 ]; then
  echo "RUN-PASS：4/4 判定符合预期"
  exit 0
fi
echo "RUN-FAIL：$pass/4 判定符合预期" >&2
exit 1
