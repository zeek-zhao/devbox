#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-008-clippy-warnings"
mkdir -p "$WORK"
cp Cargo.toml "$WORK/"
cp -R src "$WORK/"
export CARGO_TARGET_DIR="$WORK/target"
cargo clippy --manifest-path "$WORK/Cargo.toml" --offline --all-targets --quiet -- -D warnings
printf 'clippy gate: passed\n'
