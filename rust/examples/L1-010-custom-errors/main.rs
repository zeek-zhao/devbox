use std::error::Error;
use std::fmt;
use std::num::{IntErrorKind, ParseIntError};
use std::str::Utf8Error;

#[derive(Debug)]
enum IndexError {
    DocumentId(ParseIntError),
    DocumentText(Utf8Error),
}

impl From<ParseIntError> for IndexError {
    fn from(error: ParseIntError) -> Self {
        Self::DocumentId(error)
    }
}

impl From<Utf8Error> for IndexError {
    fn from(error: Utf8Error) -> Self {
        Self::DocumentText(error)
    }
}

impl fmt::Display for IndexError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::DocumentId(error) => write!(formatter, "document id: {error}"),
            Self::DocumentText(error) => write!(formatter, "document text: {error}"),
        }
    }
}

impl Error for IndexError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::DocumentId(error) => Some(error),
            Self::DocumentText(error) => Some(error),
        }
    }
}

fn parse_record(bytes: &[u8]) -> Result<u32, IndexError> {
    let text = std::str::from_utf8(bytes)?;
    let document_id = text.parse::<u32>()?;
    Ok(document_id)
}

fn main() {
    let cases: &[&[u8]] = &[b"7", b"seven", &[0xff]];
    for bytes in cases {
        match parse_record(bytes) {
            Ok(document_id) => {
                assert_eq!(document_id, 7);
                println!("record id: {document_id}");
            }
            Err(error) => {
                let preserved = match &error {
                    IndexError::DocumentId(source) => {
                        assert_eq!(source.kind(), &IntErrorKind::InvalidDigit);
                        println!("index error: document-id/invalid-digit");
                        error
                            .source()
                            .is_some_and(|value| value.is::<ParseIntError>())
                    }
                    IndexError::DocumentText(source) => {
                        assert_eq!(source.valid_up_to(), 0);
                        println!("index error: document-text/invalid-utf8");
                        error.source().is_some_and(|value| value.is::<Utf8Error>())
                    }
                };
                assert!(preserved);
                println!("source preserved: {preserved}");
            }
        }
    }
}
