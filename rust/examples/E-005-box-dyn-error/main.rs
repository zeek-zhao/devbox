// E-005 Box<dyn Error>：异构错误源在边界统一成 trait object；
// downcast_ref 在需要针对性恢复时取回具体类型。适合快速原型与统一边界；
// 调用方需要按类别稳定分支时，具体 enum 是更强的契约。

use std::error::Error;
use std::fmt;
use std::num::ParseIntError;

#[derive(Debug)]
struct MalformedRecordError {
    index: usize,
}

impl fmt::Display for MalformedRecordError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "malformed record at index {}", self.index)
    }
}

impl Error for MalformedRecordError {}

fn parse_record(index: usize, raw: &str) -> Result<u32, Box<dyn Error>> {
    if raw.is_empty() {
        return Err(Box::new(MalformedRecordError { index }));
    }
    // ParseIntError 经 From 自动装箱成 Box<dyn Error>。
    let id: u32 = raw.parse()?;
    Ok(id)
}

fn main() {
    let records = [("42", "id"), ("", "name"), ("seven", "port")];
    let mut handled = 0;

    for (index, (raw, field)) in records.iter().enumerate() {
        match parse_record(index, raw) {
            Ok(id) => println!("record {index}: id {id}"),
            Err(error) => {
                if error.downcast_ref::<ParseIntError>().is_some() {
                    println!("record {index}: parse failure on {field} -> use default id 0");
                    handled += 1;
                } else if error.downcast_ref::<MalformedRecordError>().is_some() {
                    println!("record {index}: malformed -> skip entry");
                    handled += 1;
                } else {
                    println!("record {index}: unknown failure -> propagate");
                }
            }
        }
    }
    println!("heterogeneous errors handled at one boundary: {handled}");
}
