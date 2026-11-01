#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L2-013-build-script"
mkdir -p "$WORK/project/src"
cp main.rs "$WORK/project/src/main.rs"
cat > "$WORK/project/Cargo.toml" <<'EOF'
[package]
name = "build_script_demo"
version = "0.1.0"
edition = "2021"
build = "build.rs"

[workspace]
EOF
cat > "$WORK/project/build.rs" <<'EOF'
fn main() {
    println!("cargo:rustc-env=BUILD_LABEL=generated");
    println!("cargo:rerun-if-changed=build.rs");
}
EOF
export CARGO_HOME="$WORK/cargo-home"
cd "$WORK/project"
cargo run --offline --quiet
