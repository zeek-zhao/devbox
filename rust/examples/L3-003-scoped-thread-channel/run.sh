#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L3-003-scoped-thread-channel"
rustc -O main.rs -o "$OUT"
"$OUT"
