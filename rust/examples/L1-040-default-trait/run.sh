#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-040-default-trait"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
