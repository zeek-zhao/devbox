#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-041-const-generics"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
