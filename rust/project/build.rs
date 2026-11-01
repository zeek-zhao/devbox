fn main() {
    println!("cargo:rustc-env=DEVBOX_BUILD_MARKER=rust-project");
    println!("cargo:rerun-if-changed=build.rs");
}
