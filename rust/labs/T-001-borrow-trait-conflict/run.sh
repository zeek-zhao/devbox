#!/usr/bin/env bash
# T-001-borrow-trait-conflict 演练入口：rustc → cargo → 修特征冲突看借用错浮出 →
# 修复版编译运行 → clippy/rustfmt 门禁对照，五步串完整流程。
# 工具（rustc / cargo / clippy / rustfmt）预装在 devbox-rust 镜像里（rust/docs/工具指南.md §1），
# 请在容器内运行，例如：
#   docker run --rm -v "$PWD":/work -w /work \
#     ghcr.io/zeek-zhao/devbox-rust:latest bash rust/labs/T-001-borrow-trait-conflict/run.sh
# 产物只写临时目录，不入库。用法：bash run.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

RUSTC="${RUSTC:-rustc}"
BUILD="${TMPDIR:-/tmp}/devbox-rust-T-001-borrow-trait-conflict"
PROJ="$BUILD/proj"
mkdir -p "$PROJ/src"
# 输出归一化：0x 地址在两次运行间不同就打成占位符（docs/72 §2；rustc 诊断当前不带地址，归一化是保险）。
norm() { sed -E 's/0x[0-9a-fA-F]+/0xADDR/g'; }

pass=0
step() { echo; echo "=== [step $1] $2 ==="; }
ok()  { echo "  -> 符合预期"; pass=$((pass + 1)); }
bad() { echo "  -> 不符合预期：$1" >&2; }

step 1 "rustc 直译缺陷版：特征冲突（E0119）报出，借用错（E0502）被掩蔽"
"$RUSTC" --edition 2021 main.rs -o "$BUILD/buggy" 2>"$BUILD/rustc-buggy.log"
rc=$?
grep -E 'error(\[E[0-9]+\])?:|-->|first implementation|conflicting|aborting|explain' \
  "$BUILD/rustc-buggy.log" | head -10 | sed 's/^/  | /'
if [ "$rc" -ne 0 ] && grep -q 'E0119' "$BUILD/rustc-buggy.log" \
  && ! grep -q 'E0502' "$BUILD/rustc-buggy.log"; then
  ok
  echo "  (注意掩蔽：coherence/特征一致性检查在编译管线里先于借用检查——E0119 一报就"
  echo "   aborting，E0502 根本没轮到跑。诊断里只见一个 error ≠ 只有一个缺陷，"
  echo "   与样板 C lab 的「崩溃掩盖缺陷」同构。报错行在 impl Describe for String（16 行），"
  echo "   但真正的冲突源头是 10 行的 blanket impl——报错点与病因也不重合)"
else
  bad "rustc 应非零退出且报 E0119、不报 E0502；实际不符（工具链版本漂移？）停止排查"
fi

step 2 "cargo check（构建系统视角）：同一条错、同一处行号"
cat > "$PROJ/Cargo.toml" <<TOML
[package]
name = "lab-check"
version = "0.1.0"
edition = "2021"
TOML
cp main.rs "$PROJ/src/main.rs"
clog="$BUILD/cargo-buggy.log"
if (cd "$PROJ" && cargo check --offline --color never 2>&1) >"$clog"; then
  bad "cargo check 竟通过，特征冲突未被触发"
else
  crc=$?
  grep -E 'error(\[E[0-9]+\])?:|-->|explain|could not compile' "$clog" | head -8 | sed 's/^/  | /'
  if grep -q 'E0119' "$clog" && [ "$crc" -ne 0 ]; then
    ok
    echo "  (cargo 与 rustc 报同一条 E0119、同一处 main.rs:16——cargo 只是壳，"
    echo "   诊断本体来自 rustc，两条路径互证；退出码同样非零)"
  else
    bad "cargo check 应报 E0119 且非零退出"
  fi
fi

step 3 "修掉特征冲突（blanket impl 收窄为 i32）：借用错 E0502 立刻浮出"
sed 's/impl<T: std::fmt::Debug> Describe for T {/impl Describe for i32 {/' main.rs > "$BUILD/step1.rs"
slog="$BUILD/rustc-step1.log"
"$RUSTC" --edition 2021 "$BUILD/step1.rs" -o "$BUILD/step1" 2>"$slog"
src=$?
grep -E 'error(\[E[0-9]+\])?:|-->|occurs here|later used here|aborting|explain' \
  "$slog" | head -12 | sed 's/^/  | /'
if [ "$src" -ne 0 ] && grep -q 'E0502' "$slog" && ! grep -q 'E0119' "$slog"; then
  ok
  echo "  (E0119 消失、E0502 浮出——编译器按阶段报错：修掉一个，下一个才轮到。"
  echo "   逐个修 ≠ 逐个产生：第二个缺陷一直在源码里，只是第一轮没轮到它上场)"
else
  bad "修复副本应非零退出且报 E0502、不报 E0119；实际不符停止排查"
fi

step 4 "再修借用（&scores[0] 改 scores[0]，i32 是 Copy，借改拷）：编译通过 + 运行健康对照"
sed 's/let first = &scores\[0\];/let first = scores[0];/' "$BUILD/step1.rs" > "$BUILD/fixed.rs"
flog="$BUILD/rustc-fixed.log"
if "$RUSTC" --edition 2021 "$BUILD/fixed.rs" -o "$BUILD/fixed" 2>"$flog"; then
  out="$("$BUILD/fixed" 2>&1)"
  frc=$?
  echo "$out"
  if [ "$frc" -eq 0 ] && grep -q 'run: start' <<<"$out" \
    && grep -q 'first=90 total=4' <<<"$out" && grep -q '字符串: 你好' <<<"$out"; then
    ok
    echo "  (退出码 0 + 标记行 run: start / first=90 total=4 / 字符串: 你好（素材 S-06："
    echo "   二进制确实被执行过）。两处都修完才算修好——只修特征冲突时程序根本编译不过)"
  else
    bad "修复版应退出 0 且打印 run: start / first=90 total=4 / 字符串: 你好"
  fi
else
  bad "修复版应编译通过；实际仍报错：" >&2
  grep -E 'error' "$flog" | head -5 | sed 's/^/  | /' >&2
fi

step 5 "clippy -D warnings + rustfmt --check（修复版，对齐 CI lint/格式门禁）"
cp "$BUILD/fixed.rs" "$PROJ/src/main.rs"
klog="$BUILD/clippy-fixed.log"
if (cd "$PROJ" && cargo clippy --offline --all-targets --color never -- -D warnings 2>&1) >"$klog"; then
  ok
  echo "  (clippy 门禁通过：修复版 0 警告。缺陷现场 main.rs 本身也已过 rustfmt --check——"
  echo "   格式门禁不管缺陷，只管风格；lint/格式绿 + 编译绿 + 行为对，四样齐了才算修好)"
else
  bad "修复版 clippy 应 0 警告：" >&2
  tail -10 "$klog" | sed 's/^/  | /' >&2
fi

echo
if [ "$pass" -eq 5 ]; then
  echo "RUN-PASS：5/5 判定符合预期"
  exit 0
fi
echo "RUN-FAIL：$pass/5 判定符合预期" >&2
exit 1
