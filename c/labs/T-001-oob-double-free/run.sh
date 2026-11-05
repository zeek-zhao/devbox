#!/usr/bin/env bash
# T-001-oob-double-free 演练入口：裸跑 → ASan → ASan-recover → valgrind → gdb batch，五步串完整流程。
# 工具（gcc / valgrind / gdb）预装在 devbox-cpp 镜像里（C 复用 cpp 层，真本 images/lang-images.tsv；
# c/docs/工具指南.md §1），请在容器内运行，例如：
#   docker run --rm -v "$PWD":/work -w /work \
#     ghcr.io/zeek-zhao/devbox-cpp:latest bash c/labs/T-001-oob-double-free/run.sh
# 产物只写临时目录，不入库。用法：bash run.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

CC="${CC:-gcc}"
BUILD="${TMPDIR:-/tmp}/devbox-c-T-001-oob-double-free"
PLAIN="$BUILD/buggy-plain"
ASAN="$BUILD/buggy-asan"
RECOVER="$BUILD/buggy-asan-recover"
mkdir -p "$BUILD"
# 输出归一化：0x 地址与 ==pid== 前缀在两次运行间必然不同，展示前先打成占位符（docs/72 §2）。
norm() { sed -E 's/0x[0-9a-fA-F]+/0xADDR/g; s/==[0-9]+==/==N==/g'; }

FLAGS="-std=c17 -Wall -Wextra -pedantic -g -O0 -fno-omit-frame-pointer"
pass=0
step() { echo; echo "=== [step $1] $2 ==="; }
ok()  { echo "  -> 符合预期"; pass=$((pass + 1)); }
bad() { echo "  -> 不符合预期：$1" >&2; }

step 1 "裸跑（无工具构建）：死于下游 glibc 断言，报错点不在病因上"
"$CC" $FLAGS main.c -o "$PLAIN" 2>"$BUILD/ccwarn.log" || { echo "编译失败" >&2; exit 2; }
if [ -s "$BUILD/ccwarn.log" ]; then
  echo "  (编译期已有线索：gcc -Wall 对第二个 free(buf) 报 -Wuse-after-free——第一道防线，"
  echo "   但只是警告，构建照样成功，两个缺陷全部带进了二进制)"
  grep -E 'warning|note' "$BUILD/ccwarn.log" | head -4 | sed 's/^/  | /'
fi
out="$("$PLAIN" 2>&1)"
rc=$?
echo "$out"
if [ "$rc" -ne 0 ] && grep -q 'run: start' <<<"$out" && grep -q 'sum=45 tag=A' <<<"$out" \
  && grep -Eq 'munmap_chunk|free\(\):|malloc\(\):|corrupted' <<<"$out"; then
  ok
  echo "  (退出码 $rc 非零 + 标记行 run: start / sum=45 tag=A 已打印（素材 S-06：二进制确实被执行过）。"
  echo "   注意两件事：① glibc 断言报在 free(tag) 附近，tag 是无辜的——病因是 main.c:27 的越界写"
  echo "   踩坏相邻 chunk 元数据，症状与病因相距甚远；② 程序死在 main.c:37 之前，第二个 free(buf)"
  echo "   （缺陷 2）根本没执行到——一次崩溃掩盖了另一个缺陷。同一份代码换一次分配顺序，"
  echo "   裸跑结局可能不同（见 WALKTHROUGH POE 点）)"
else
  bad "裸跑应非零退出且带 glibc 内存断言 + 标记行；若 run: start 缺失，先怀疑二进制未真正执行（S-06），再谈代码"
fi

step 2 "ASan 构建（默认 halt）：在越界写现场精确截停"
"$CC" $FLAGS -fsanitize=address main.c -o "$ASAN" 2>>"$BUILD/ccwarn.log" || { echo "编译失败" >&2; exit 2; }
alog="$BUILD/asan.log"
if "$ASAN" >"$alog" 2>&1; then
  bad "ASan 构建竟退出 0，越界未被捕获"
else
  arc=$?
  ok
  echo "  (ASan 退出码 $arc；报告头与关键行（已归一化）如下)"
  grep -E 'ERROR: AddressSanitizer|WRITE of size|#0 |#1 |located|SUMMARY' \
    "$alog" | head -8 | norm | sed 's/^/  | /'
fi

step 3 "ASan recover 模式（halt_on_error=0）：两个缺陷一份报告全现形"
"$CC" $FLAGS -fsanitize=address -fsanitize-recover=address main.c -o "$RECOVER" 2>>"$BUILD/ccwarn.log" || { echo "编译失败" >&2; exit 2; }
rlog="$BUILD/asan-recover.log"
ASAN_OPTIONS=halt_on_error=0:detect_leaks=0 "$RECOVER" >"$rlog" 2>&1
rrc=$?
grep -E 'ERROR: AddressSanitizer|WRITE of size|#0 |freed by thread|previously allocated|SUMMARY' \
  "$rlog" | head -12 | norm | sed 's/^/  | /'
if grep -q 'heap-buffer-overflow' "$rlog" && grep -q 'attempting double-free' "$rlog"; then
  ok
  echo "  (两个 ERROR 同场出现：heap-buffer-overflow 指向 main.c:27，double-free 指向 main.c:37"
  echo "   并给出 freed by 栈（main.c:35）。注意 recover 模式的退出码 $rrc——"
  echo "   报了错却可能仍是 0，退出码会撒谎，别拿它当结论（WALKTHROUGH 假设 H4）)"
else
  bad "recover 模式应同时报 heap-buffer-overflow 与 attempting double-free；实际输出不符，停止排查"
fi

step 4 "valgrind（跑无工具构建）：越界 + 非法释放一并现形"
vlog="$BUILD/valgrind.log"
valgrind --leak-check=full --error-exitcode=42 "$PLAIN" >"$vlog" 2>&1
vrc=$?
grep -E 'Invalid write|Invalid free|main.c:[0-9]+|HEAP SUMMARY|in use at exit|total heap usage|ERROR SUMMARY' \
  "$vlog" | norm | sed 's/^/  | /'
if [ "$vrc" -eq 42 ] && grep -q 'Invalid write of size 4' "$vlog" && grep -q 'Invalid free' "$vlog"; then
  ok
  echo "  (退出码 42 来自 --error-exitcode：valgrind 把『发生过错误』变成可判定的退出码。"
  echo "   注意 in use at exit: 0 bytes——本 lab 没有泄漏缺陷，与样板 lab 的 leak 场景互为对照)"
else
  bad "valgrind 应以 42 退出且同时命中 Invalid write / Invalid free"
fi

step 5 "gdb batch（跑 ASan 构建）：在故障现场取调用栈"
glog="$BUILD/gdb.log"
# abort_on_error=1 让 ASan 以 SIGABRT 停下，gdb 才能接到现场打 bt（默认行为是直接 exit 1）。
ASAN_OPTIONS=abort_on_error=1:detect_leaks=0 \
  gdb -batch -ex run -ex bt --args "$ASAN" >"$glog" 2>&1 || true
grep -E 'ERROR: AddressSanitizer|Program received|in main' "$glog" | head -8 | norm | sed 's/^/  | /'
if grep -q 'heap-buffer-overflow' "$glog" && grep -q 'at main.c:27' "$glog"; then
  ok
  echo "  (gdb 回溯在 SIGABRT 现场给出 main.c:27，与 ASan 报告的故障行互证)"
else
  bad "gdb 输出中未见 ASan 报告或 main.c:27 行号"
fi

echo
if [ "$pass" -eq 5 ]; then
  echo "RUN-PASS：5/5 判定符合预期"
  exit 0
fi
echo "RUN-FAIL：$pass/5 判定符合预期" >&2
exit 1
