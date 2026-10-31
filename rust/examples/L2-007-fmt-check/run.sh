#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-007-fmt-check"
mkdir -p "$WORK/project"
cp Cargo.toml "$WORK/project/"
cp -R src "$WORK/project/"
export CARGO_TARGET_DIR="$WORK/target"
cd "$WORK/project"
if cargo --offline fmt --check >/dev/null 2>&1; then
    printf 'format check: passed\n'
else
    printf 'format check: failed\n'
    exit 1
fi
