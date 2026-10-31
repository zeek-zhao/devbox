#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-009-offline-build"
mkdir -p "$WORK"
cp Cargo.toml "$WORK/"
cp -R src "$WORK/"
export CARGO_TARGET_DIR="$WORK/target"
cargo build --manifest-path "$WORK/Cargo.toml" --offline --quiet
if cargo test --manifest-path "$WORK/Cargo.toml" --offline --quiet >"$WORK/tests.log" 2>&1; then
    :
else
    cat "$WORK/tests.log" >&2
    exit 1
fi
cargo tree --manifest-path "$WORK/Cargo.toml" --offline --prefix none >"$WORK/dependencies.txt"
test "$(wc -l < "$WORK/dependencies.txt")" -eq 1
"$CARGO_TARGET_DIR/debug/offline-build"
