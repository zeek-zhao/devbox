#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-016-cargo-doc-links"
mkdir -p "$WORK/project/src"
cp main.rs "$WORK/project/src/main.rs"
cat > "$WORK/project/Cargo.toml" <<'EOF'
[package]
name = "cargo_doc_links"
version = "0.1.0"
edition = "2021"

[workspace]
EOF
export CARGO_HOME="$WORK/cargo-home"
cd "$WORK/project"
RUSTDOCFLAGS="-D rustdoc::broken_intra_doc_links" cargo doc --offline --no-deps --quiet
cargo run --offline --quiet
