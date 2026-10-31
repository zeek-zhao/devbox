#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-011-cargo-examples"
mkdir -p "$WORK"
cp Cargo.toml "$WORK/"
cp -R src examples "$WORK/"
export CARGO_TARGET_DIR="$WORK/target"
cargo run --manifest-path "$WORK/Cargo.toml" --example public-api --offline --quiet
