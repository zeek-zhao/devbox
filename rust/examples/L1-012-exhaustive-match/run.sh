#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-012-exhaustive-match"
rustc -O main.rs -o "$OUT"
"$OUT"
