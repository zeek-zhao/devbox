#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-002-cargo-modules"
mkdir -p "$WORK/project"
cp Cargo.toml "$WORK/project/"
cp -R src "$WORK/project/"
export CARGO_TARGET_DIR="$WORK/target"
cd "$WORK/project"
cargo build --offline --quiet
"$CARGO_TARGET_DIR/debug/cargo_modules"
