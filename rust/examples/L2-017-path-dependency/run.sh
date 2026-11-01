#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-017-path-dependency"
mkdir -p "$WORK/project/src" "$WORK/project/helper/src"
cp main.rs "$WORK/project/src/main.rs"
cat > "$WORK/project/Cargo.toml" <<'EOF'
[package]
name = "path_dependency_demo"
version = "0.1.0"
edition = "2021"

[workspace]
members = [".", "helper"]

[dependencies]
local_alias = { path = "helper", package = "offline_helper" }
EOF
cat > "$WORK/project/helper/Cargo.toml" <<'EOF'
[package]
name = "offline_helper"
version = "0.1.0"
edition = "2021"
EOF
cat > "$WORK/project/helper/src/lib.rs" <<'EOF'
pub fn label() -> &'static str { "offline-helper" }
EOF
export CARGO_HOME="$WORK/cargo-home"
cd "$WORK/project"
cargo run --offline --quiet
