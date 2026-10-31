#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-003-shared-borrows"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
