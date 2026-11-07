// E-014 反模式对照：吞错（.ok() 丢因）、stringly-typed 错误（Err(String)）、
// 错误后继续跑（坏行静默消失）。每组反模式与修正版成对输出。

use std::error::Error;
use std::fmt;
use std::num::ParseIntError;

#[derive(Debug)]
enum ConfigError {
    Port(ParseIntError),
}

impl fmt::Display for ConfigError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Port(source) => write!(formatter, "config port: {source}"),
        }
    }
}

impl Error for ConfigError {}

/// 反模式 2 的反面教材：Err(String) 丢掉类型，调用方只能对文本做约定。
fn load_stringly_typed(raw: &str) -> Result<u32, String> {
    raw.parse::<u32>().map_err(|error| format!("port: {error}"))
}

fn main() {
    // ---- 反模式 1：吞错。`.ok()` 把 Err 拍成 None，失败原因彻底消失。
    let swallowed = "bad".parse::<u32>().ok();
    println!(
        "anti-1 swallowed: {:?} (error cause destroyed by .ok())",
        swallowed.is_none()
    );
    let surfaced: Result<u32, ParseIntError> = "bad".parse::<u32>();
    println!("anti-1 fixed: {surfaced:?}");

    // ---- 反模式 2：stringly-typed 错误。Err(String) 无法按类别分支。
    let text_error = load_stringly_typed("x").unwrap_err();
    println!(
        "anti-2 stringly-typed: caller matches on message text only ({})",
        text_error.starts_with("port:")
    );
    let typed_error = ConfigError::Port("x".parse::<u32>().unwrap_err());
    println!(
        "anti-2 fixed: variant ConfigError::Port matches by type ({})",
        matches!(typed_error, ConfigError::Port(_))
    );

    // ---- 反模式 3：错误后继续跑。坏行按 0 混过，总数静默失真。
    let rows = ["1", "x", "4"];
    let poisoned_total: u32 = rows.iter().filter_map(|raw| raw.parse::<u32>().ok()).sum();
    println!("anti-3 continue-on-error: total {poisoned_total} (bad rows silently vanish)");
    let checked: Result<u32, ParseIntError> = rows.iter().map(|raw| raw.parse::<u32>()).sum();
    println!(
        "anti-3 fixed: {}",
        match checked {
            Ok(total) => format!("total {total}"),
            Err(error) => format!("aborted ({error})"),
        }
    );
}
