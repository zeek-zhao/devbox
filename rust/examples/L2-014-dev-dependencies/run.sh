#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-014-dev-dependencies"
mkdir -p "$WORK/project/src" "$WORK/project/dev-support/src"
cp main.rs "$WORK/project/src/main.rs"
cat > "$WORK/project/Cargo.toml" <<'EOF'
[package]
name = "dev_dependencies_demo"
version = "0.1.0"
edition = "2021"

[workspace]
members = [".", "dev-support"]

[dev-dependencies]
dev_support = { path = "dev-support" }
EOF
cat > "$WORK/project/dev-support/Cargo.toml" <<'EOF'
[package]
name = "dev_support"
version = "0.1.0"
edition = "2021"
EOF
cat > "$WORK/project/dev-support/src/lib.rs" <<'EOF'
pub fn marker() -> &'static str { "test-only" }
EOF
export CARGO_HOME="$WORK/cargo-home"
cd "$WORK/project"
cargo test --offline --quiet >/dev/null
cargo run --offline --quiet
