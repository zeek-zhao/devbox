#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L3-009-handmade-future"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
