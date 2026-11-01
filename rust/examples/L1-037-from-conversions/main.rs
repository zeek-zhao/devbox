use std::convert::{From, TryFrom};
use std::num::ParseIntError;

#[derive(Debug)]
struct ConfigError(String);

impl From<ParseIntError> for ConfigError {
    fn from(error: ParseIntError) -> Self {
        Self(error.to_string())
    }
}

fn parse_port(text: &str) -> Result<u16, ConfigError> {
    let value = text.parse::<u32>()?;
    u16::try_from(value).map_err(|error| ConfigError(error.to_string()))
}

fn main() {
    let owned: String = "8080".into();
    let port = parse_port(&owned).unwrap();
    println!("port: {port}");
    println!("overflow rejected: {}", parse_port("70000").is_err());
    println!(
        "parse error converted: {}",
        parse_port("x").unwrap_err().0.contains("invalid digit")
    );
    println!("parse rejected: {}", parse_port("x").is_err());
}
