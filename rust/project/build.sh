#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$ROOT/../.." && pwd)"
cd "$ROOT"
mkdir -p build
if command -v cargo >/dev/null 2>&1; then
  cargo fmt --all -- --check # L2-007-fmt-check
  cargo clippy --offline --all-targets -- -D warnings # L2-008-clippy-warnings
  cargo test --offline --all-targets --all-features # L2-009-offline-build
  cargo build --release --offline
else
  IMAGE="ghcr.io/zeek-zhao/devbox-rust:${TAG:-latest}"
  if ! docker image inspect "$IMAGE" >/dev/null; then
    echo "[fail] cargo 不在宿主机且 Rust 构建镜像不在本地: $IMAGE" >&2
    exit 1
  fi
  docker run --rm -v "$REPO_ROOT:/workspace" -w /workspace/rust/project \
    "$IMAGE" bash -lc 'set -euo pipefail
cargo fmt --all -- --check
cargo clippy --offline --all-targets -- -D warnings
cargo test --offline --all-targets --all-features
cargo build --release --offline'
fi
cp target/release/devbox-rust-project build/devbox-rust-project
