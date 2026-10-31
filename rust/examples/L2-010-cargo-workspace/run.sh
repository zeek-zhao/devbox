#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-010-cargo-workspace"
mkdir -p "$WORK"
cp Cargo.toml "$WORK/"
cp -R core cli "$WORK/"
export CARGO_TARGET_DIR="$WORK/target"
if cargo test --manifest-path "$WORK/Cargo.toml" --workspace --offline --quiet >"$WORK/tests.log" 2>&1; then
    :
else
    cat "$WORK/tests.log" >&2
    exit 1
fi
printf 'workspace tests: 2 members passed\n'
