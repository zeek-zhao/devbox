#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-005-doctests"
mkdir -p "$WORK/project"
cp Cargo.toml "$WORK/project/"
cp -R src "$WORK/project/"
export CARGO_TARGET_DIR="$WORK/target"
cd "$WORK/project"
if ! cargo test --doc --offline --quiet >/dev/null; then
    exit 1
fi
cargo test --doc --offline --quiet 2>&1 | sed -E 's/finished in [0-9.]+s//' | sed -E '/^[[:space:]]*$/d' | sed -E 's/[[:space:]]+$//'
