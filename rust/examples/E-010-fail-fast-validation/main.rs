// E-010 快速失败：先整体校验，再执行任何副作用；校验不过就一步都不走，
// 拒绝信息精确到行。对照「边解析边执行」的部分副作用形态。

use std::error::Error;
use std::fmt;

#[derive(Debug)]
struct Request {
    id: u32,
    amount: u32,
}

#[derive(Debug)]
enum ValidationError {
    EmptyBatch,
    InvalidId { line: usize, raw: String },
    InvalidAmount { line: usize },
}

impl fmt::Display for ValidationError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::EmptyBatch => write!(formatter, "empty batch"),
            Self::InvalidId { line, raw } => {
                write!(formatter, "invalid id at line {line}: `{raw}`")
            }
            Self::InvalidAmount { line } => {
                write!(formatter, "invalid amount at line {line}")
            }
        }
    }
}

impl Error for ValidationError {}

/// 先全量校验，任何一个字段非法都整体拒绝，不返回半成品。
fn validate(raws: &[(&str, &str)]) -> Result<Vec<Request>, ValidationError> {
    if raws.is_empty() {
        return Err(ValidationError::EmptyBatch);
    }
    let mut requests = Vec::new();
    for (line, (id, amount)) in raws.iter().enumerate() {
        let id = id.parse::<u32>().map_err(|_| ValidationError::InvalidId {
            line: line + 1,
            raw: (*id).to_string(),
        })?;
        let amount = amount
            .parse::<u32>()
            .map_err(|_| ValidationError::InvalidAmount { line: line + 1 })?;
        requests.push(Request { id, amount });
    }
    Ok(requests)
}

/// 副作用摘要：真实代码这里是写库/调用下游；校验不过时本函数绝不能被调到。
/// 返回应用的 id 清单与总金额，证明每条记录的字段都被真正消费。
fn apply(requests: &[Request]) -> String {
    let ids: Vec<u32> = requests.iter().map(|request| request.id).collect();
    let total: u64 = requests
        .iter()
        .map(|request| u64::from(request.amount))
        .sum();
    format!("ids {ids:?} total {total}")
}

fn main() {
    match validate(&[("1", "100"), ("2", "200")]) {
        Ok(requests) => println!("valid batch: 2 requests applied, {}", apply(&requests)),
        Err(error) => println!("valid batch rejected: {error}"),
    }

    // 第 2 行 id 非法：整个批次被拒，一次副作用都没发生。
    match validate(&[("1", "100"), ("bad", "200")]) {
        Ok(requests) => {
            println!("bad batch accepted: {} (unexpected)", apply(&requests));
        }
        Err(error) => println!("invalid batch rejected before any side effect: {error}"),
    }

    match validate(&[]) {
        Ok(_) => println!("empty batch accepted (unexpected)"),
        Err(error) => println!("empty batch rejected: {error}"),
    }

    match validate(&[("1", "100"), ("2", "lots")]) {
        Ok(_) => println!("bad amount accepted (unexpected)"),
        Err(error) => println!("bad amount rejected: {error}"),
    }
}
