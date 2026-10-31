#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-006-cargo-features"
mkdir -p "$WORK/project"
cp Cargo.toml "$WORK/project/"
cp -R src "$WORK/project/"
export CARGO_TARGET_DIR="$WORK/target"
cd "$WORK/project"
cargo run --offline --quiet
cargo run --offline --quiet --features diagnostics
