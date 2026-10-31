#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-003-unit-tests"
mkdir -p "$WORK/project"
cp Cargo.toml "$WORK/project/"
cp -R src "$WORK/project/"
export CARGO_TARGET_DIR="$WORK/target"
cd "$WORK/project"
if ! cargo test --offline --quiet >/dev/null; then
    exit 1
fi
cargo test --offline --quiet 2>&1 | sed -E 's/finished in [0-9.]+s//' | sed -E '/^[[:space:]]*$/d' | sed -E 's/[[:space:]]+$//'
