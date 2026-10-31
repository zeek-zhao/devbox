#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-016-trait-default-methods"
rustc -O main.rs -o "$OUT"
"$OUT"
