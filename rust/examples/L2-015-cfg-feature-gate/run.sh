#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-015-cfg-feature-gate"
mkdir -p "$WORK/project/src"
cp main.rs "$WORK/project/src/main.rs"
cat > "$WORK/project/Cargo.toml" <<'EOF'
[package]
name = "cfg_feature_demo"
version = "0.1.0"
edition = "2021"

[workspace]

[features]
trace = []
EOF
export CARGO_HOME="$WORK/cargo-home"
cd "$WORK/project"
cargo run --offline --quiet
cargo run --offline --quiet --features trace
