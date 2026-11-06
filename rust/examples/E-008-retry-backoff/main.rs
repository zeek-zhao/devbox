// E-008 重试与退避：瞬时错误按指数退避重试并设上限，永久错误立即上抛
// 不重试。重试的前提是错误分类——不分类的重试只会放大故障。

use std::error::Error;
use std::fmt;
use std::thread;
use std::time::Duration;

#[derive(Debug)]
enum FetchError {
    /// 瞬时错误：超时、限流等，下一次尝试可能成功。
    Transient,
    /// 永久错误：重试不会改变结果，只会放大故障。
    Permanent(String),
}

impl fmt::Display for FetchError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Transient => write!(formatter, "transient fetch failure"),
            Self::Permanent(reason) => write!(formatter, "permanent fetch failure: {reason}"),
        }
    }
}

impl Error for FetchError {}

/// 模拟远端：第 3 次尝试才成功，前两次报瞬时错误。
fn fetch(attempt: u32) -> Result<&'static str, FetchError> {
    if attempt < 3 {
        Err(FetchError::Transient)
    } else {
        Ok("payload")
    }
}

/// 模拟远端：无论重试多少次都失败，属永久错误。
fn fetch_broken(_attempt: u32) -> Result<&'static str, FetchError> {
    Err(FetchError::Permanent("schema mismatch".to_string()))
}

/// 指数退避重试：1ms、2ms、4ms……（演示基数，真实场景按 SLO 定）；
/// 上限 5 次；Permanent 直接穿透，绝不重试。
fn with_retry<F>(mut operation: F) -> Result<&'static str, FetchError>
where
    F: FnMut(u32) -> Result<&'static str, FetchError>,
{
    let mut attempt = 1;
    loop {
        match operation(attempt) {
            Ok(value) => return Ok(value),
            Err(FetchError::Permanent(reason)) => return Err(FetchError::Permanent(reason)),
            Err(FetchError::Transient) => {
                if attempt >= 5 {
                    return Err(FetchError::Transient);
                }
                thread::sleep(Duration::from_millis(1 << (attempt - 1)));
                attempt += 1;
            }
        }
    }
}

fn main() {
    match with_retry(fetch) {
        Ok(value) => println!("retry: recovered after transient errors, value {value}"),
        Err(_) => println!("retry: unexpected failure"),
    }

    match with_retry(fetch_broken) {
        Ok(_) => println!("broken: unexpected success"),
        Err(FetchError::Permanent(reason)) => {
            println!("broken: no retry on permanent error ({reason})");
        }
        Err(FetchError::Transient) => println!("broken: unexpected transient"),
    }

    println!("policy: retry transient with exponential backoff, fail fast on permanent");
}
