#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L3-011-send-sync-bounds"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"

NEGATIVE="${TMPDIR:-/tmp}/devbox-rust-L3-011-not-send.rs"
ERROR="${TMPDIR:-/tmp}/devbox-rust-L3-011-not-send.err"
cat > "$NEGATIVE" <<'EOF'
use std::rc::Rc;
use std::thread;
fn main() {
    let value = Rc::new(1);
    thread::spawn(move || println!("{value}"));
}
EOF
if rustc --edition=2021 "$NEGATIVE" -o "${TMPDIR:-/tmp}/devbox-rust-L3-011-negative" 2>"$ERROR"; then
    echo "Rc unexpectedly compiled as Send" >&2
    exit 1
fi
grep -q "Send" "$ERROR"
echo "negative compile rejected Rc: Send"
