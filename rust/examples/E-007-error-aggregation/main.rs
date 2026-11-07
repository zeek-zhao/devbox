// E-007 错误聚合：批量处理收集全部失败而不是在第一个失败处短路；
// 对照 collect 的 all-or-nothing 短路语义，两者适用场景不同。

use std::error::Error;
use std::fmt;

#[derive(Debug)]
struct RowError {
    row: usize,
    reason: String,
}

impl fmt::Display for RowError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "row {}: {}", self.row, self.reason)
    }
}

impl Error for RowError {}

fn parse_row(row: usize, line: &str) -> Result<u32, RowError> {
    line.trim().parse::<u32>().map_err(|error| RowError {
        row,
        reason: error.to_string(),
    })
}

fn main() {
    let lines = ["12", "x", " 34 ", "y", "56"];

    // 聚合模式：一分为二，报告全部失败（行号 + 各自原因）。
    let mut successes: Vec<u32> = Vec::new();
    let mut failures: Vec<RowError> = Vec::new();
    for (row, line) in lines.iter().enumerate() {
        match parse_row(row, line) {
            Ok(value) => successes.push(value),
            Err(error) => failures.push(error),
        }
    }
    println!(
        "aggregated: {} ok, {} failed",
        successes.len(),
        failures.len()
    );
    for value in &successes {
        println!("ok row value: {value}");
    }
    for error in &failures {
        println!("failed: {error}");
    }

    // 对照：collect 在首个 Err 处短路——适合「要么全对，要么什么都不要」。
    let all_or_nothing: Result<Vec<u32>, RowError> = lines
        .iter()
        .enumerate()
        .map(|(row, line)| parse_row(row, line))
        .collect();
    println!("all-or-nothing short-circuits: {}", all_or_nothing.is_err());
}
