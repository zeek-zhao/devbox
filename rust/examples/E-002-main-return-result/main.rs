// E-002 主函数返回 Result：错误沿 std 定义的路径变成退出码 1 + stderr 诊断行
// `Error: <Debug>`。这是 CLI 最薄的错误处理层：不写 match，也能拿到失败语义。

use std::error::Error;
use std::fmt;
use std::num::ParseIntError;

#[derive(Debug)]
struct ConfigError {
    field: &'static str,
    source: ParseIntError,
}

impl fmt::Display for ConfigError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "invalid config field `{}`", self.field)
    }
}

impl Error for ConfigError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        Some(&self.source)
    }
}

fn parse_workers(raw: &str) -> Result<u32, ConfigError> {
    raw.parse::<u32>().map_err(|source| ConfigError {
        field: "workers",
        source,
    })
}

fn run(mode: &str) -> Result<String, Box<dyn Error>> {
    match mode {
        "ok" => Ok("pipeline finished".to_string()),
        "bad-config" => {
            let workers = parse_workers("many")?;
            Ok(format!("workers = {workers}"))
        }
        other => Err(format!("unknown mode: {other}").into()),
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let mode = std::env::args().nth(1).unwrap_or_else(|| "ok".to_string());
    let message = run(&mode)?;
    println!("{message}");
    Ok(())
}
