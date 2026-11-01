use std::env; // hello: standard-library CLI entry point
use std::io;

use devbox_rust_project::{parse_args, run, AppError};

fn main() -> Result<(), AppError> {
    let args: Vec<String> = env::args().skip(1).collect();
    run(parse_args(&args)?, &mut io::stdout().lock())
}
