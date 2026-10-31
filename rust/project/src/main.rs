use std::env; // hello: standard-library CLI entry point
use std::io;

use devbox_rust_project::{AppError, parse_args, run};

fn main() -> Result<(), AppError> {
    let args: Vec<String> = env::args().skip(1).collect();
    run(parse_args(&args)?, &mut io::stdout().lock())
}
