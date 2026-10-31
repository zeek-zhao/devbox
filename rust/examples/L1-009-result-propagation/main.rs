use std::num::{IntErrorKind, ParseIntError};

fn parse_document_id(input: &str) -> Result<u32, ParseIntError> {
    let document_id = input.parse::<u32>()?;
    Ok(document_id)
}

fn read_argument(input: &str) -> Result<u32, ParseIntError> {
    let document_id = parse_document_id(input)?;
    Ok(document_id)
}

fn main() {
    match read_argument("7") {
        Ok(document_id) => {
            assert_eq!(document_id, 7);
            println!("valid argument: {document_id}");
        }
        Err(error) => panic!("fixed valid input failed: {error}"),
    }
    match read_argument("seven") {
        Ok(_) => panic!("invalid input unexpectedly succeeded"),
        Err(error) => {
            assert_eq!(error.kind(), &IntErrorKind::InvalidDigit);
            let direct_error = "seven".parse::<u32>().expect_err("invalid fixture");
            assert_eq!(error, direct_error);
            println!("invalid argument: invalid-digit");
            println!("same error after propagation: {}", error == direct_error);
        }
    }
    println!("boundary handled error: continued");
}
