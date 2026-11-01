#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-012-cargo-config-alias"
mkdir -p "$WORK/project/src" "$WORK/project/.cargo"
cp main.rs "$WORK/project/src/main.rs"
cat > "$WORK/project/Cargo.toml" <<'EOF'
[package]
name = "cargo_config_alias"
version = "0.1.0"
edition = "2021"

[workspace]
EOF
cat > "$WORK/project/.cargo/config.toml" <<'EOF'
[alias]
check-demo = "check --offline"

[build]
target-dir = "build-out"
EOF
export CARGO_HOME="$WORK/cargo-home"
cd "$WORK/project"
cargo check-demo --quiet
 test -d build-out/debug
cargo run --offline --quiet
