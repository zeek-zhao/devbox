// E-004 `?` 与 map_err：`expr?` 等价于按 From::from 转换后提前返回。
// 为底层错误实现 From 后整条调用链免样板；没有 From 时 map_err 是兜底。

use std::error::Error;
use std::fmt;
use std::num::ParseIntError;

#[derive(Debug, PartialEq, Eq)]
enum ConfigError {
    Port(ParseIntError),
    EmptyField,
}

impl fmt::Display for ConfigError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Port(source) => write!(formatter, "config port: {source}"),
            Self::EmptyField => write!(formatter, "config: empty field"),
        }
    }
}

impl Error for ConfigError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Port(source) => Some(source),
            Self::EmptyField => None,
        }
    }
}

impl From<ParseIntError> for ConfigError {
    fn from(source: ParseIntError) -> Self {
        Self::Port(source)
    }
}

/// 写法 A：`?` 经 From 自动转换，调用链零样板。
fn load_auto(raw: &str) -> Result<u32, ConfigError> {
    if raw.is_empty() {
        return Err(ConfigError::EmptyField);
    }
    let port: u32 = raw.parse()?;
    Ok(port)
}

/// 写法 B：map_err 手动转换，与写法 A 完全等价；目标类型没有匹配的
/// From 实现时（例如临时改成 String），map_err 是唯一选择。
fn load_manual(raw: &str) -> Result<u32, ConfigError> {
    if raw.is_empty() {
        return Err(ConfigError::EmptyField);
    }
    raw.parse().map_err(ConfigError::Port)
}

fn main() {
    let auto_ok = load_auto("8080");
    let manual_ok = load_manual("8080");
    println!("ok path equal: {}", auto_ok == manual_ok);

    let auto_err = load_auto("many").unwrap_err();
    let manual_err = load_manual("many").unwrap_err();
    println!("err path equal: {}", auto_err == manual_err);

    // 展开 `?` 的真实语义：Err(e) => return Err(From::from(e))。
    let parse_error = "many".parse::<u32>().unwrap_err();
    let via_from = ConfigError::from(parse_error.clone());
    println!("question-mark is From::from: {}", via_from == auto_err);

    println!("display keeps root cause: {}", auto_err.to_string());
    println!("prefer From when one target type dominates: yes");
}
