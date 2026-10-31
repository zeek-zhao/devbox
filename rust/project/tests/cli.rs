use devbox_rust_project::{AppError, Operation, parse_args, run}; // L2-004-integration-tests

#[test]
fn help_is_written_to_the_supplied_output() {
    let args = ["count".to_owned(), "--help".to_owned()];
    let options = parse_args(&args).unwrap();
    assert_eq!(options.operation, Operation::Help);
    let mut output = Vec::new();
    run(options, &mut output).unwrap();
    assert!(String::from_utf8(output).unwrap().starts_with("Usage:"));
}

#[test]
fn malformed_thread_count_is_a_domain_error() {
    let args = ["count".to_owned(), "--threads=zero".to_owned()];
    assert!(matches!(
        parse_args(&args),
        Err(AppError::InvalidArguments(_))
    ));
}
