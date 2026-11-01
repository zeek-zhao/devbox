use devbox_rust_project::{parse_args, run, AppError}; // L2-011-cargo-examples

fn main() -> Result<(), AppError> {
    let args = vec!["bench".to_owned()];
    run(parse_args(&args)?, &mut std::io::stdout())
}
