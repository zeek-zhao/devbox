#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-018-lazy-iterators"
rustc -O main.rs -o "$OUT"
"$OUT"
