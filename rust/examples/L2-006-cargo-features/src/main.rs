#[cfg(feature = "diagnostics")]
fn mode() -> &'static str {
    "diagnostics enabled"
}

#[cfg(not(feature = "diagnostics"))]
fn mode() -> &'static str {
    "diagnostics disabled"
}

fn main() {
    println!("{}", mode());
}
