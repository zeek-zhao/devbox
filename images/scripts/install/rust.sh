#!/usr/bin/env bash
# ==================================================================
# Rust 工具链安装（rustup，走 USTC 镜像，profile minimal + clippy/rustfmt）
# ==================================================================
set -euo pipefail

: "${RUST_TOOLCHAIN:?需要 RUST_TOOLCHAIN}"

arch="$(dpkg --print-architecture)"
case "$arch" in
  amd64) rustarch=x86_64 ;;
  arm64) rustarch=aarch64 ;;
  *) echo "不支持的架构: $arch" >&2; exit 1 ;;
esac

# 先补 rustup 自身编译/链接需要的系统库（不能在 base 装，会污染公共层）
apt-get update
apt-get install -y --no-install-recommends pkg-config libssl-dev zlib1g-dev
apt-get clean
rm -rf /var/lib/apt/lists/*

# 直连镜像取 rustup-init 二进制，避免依赖 sh.rustup.rs（墙外且不稳定）
init_url="${RUSTUP_DIST_SERVER}/rustup/dist/${rustarch}-unknown-linux-gnu/rustup-init"
echo "==> 下载 rustup-init: ${init_url}"
curl -fsSL --retry 3 --retry-delay 2 -o /tmp/rustup-init "$init_url"
chmod +x /tmp/rustup-init

export RUSTUP_HOME="${RUSTUP_HOME:-/usr/local/rustup}"
export CARGO_HOME="${CARGO_HOME:-/usr/local/cargo}"

/tmp/rustup-init -y --no-modify-path \
  --profile minimal \
  --default-toolchain "${RUST_TOOLCHAIN}"
rm -f /tmp/rustup-init

# rustup 装完后组件再补：minimal profile 不含 clippy/rustfmt
"${CARGO_HOME}/bin/rustup" component add clippy rustfmt

chmod -R 0777 "${CARGO_HOME}" "${RUSTUP_HOME}"

echo "==> 自检"
"${CARGO_HOME}/bin/rustc" --version
"${CARGO_HOME}/bin/cargo" --version
"${CARGO_HOME}/bin/cargo" clippy --version
"${CARGO_HOME}/bin/rustfmt" --version
