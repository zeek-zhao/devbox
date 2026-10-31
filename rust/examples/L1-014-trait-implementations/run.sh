#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-014-trait-implementations"
rustc -O main.rs -o "$OUT"
"$OUT"
