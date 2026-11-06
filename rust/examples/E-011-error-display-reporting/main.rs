// E-011 Display 与 Debug：同一个错误值提供两个视图——Display 面向用户
// （稳定文案、不暴露内部细节），Debug 面向排障者（全量结构诊断）。

use std::error::Error;
use std::fmt;
use std::num::ParseIntError;

#[derive(Debug)]
struct PaymentError {
    reference: &'static str,
    source: ParseIntError,
}

impl fmt::Display for PaymentError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "payment {} failed", self.reference)
    }
}

impl Error for PaymentError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        Some(&self.source)
    }
}

fn charge(amount: &str) -> Result<u64, PaymentError> {
    let cents = amount.parse::<u64>().map_err(|source| PaymentError {
        reference: "PAY-1234",
        source,
    })?;
    Ok(cents)
}

fn main() {
    match charge("19.9") {
        Ok(cents) => println!("charged {cents} cents"),
        Err(error) => {
            // 用户视图：Display——稳定、可翻译、不随内部实现漂移。
            println!("user view: {error}");
            // 排障视图：Debug——完整结构，写进日志/工单。
            println!("operator view: {error:?}");
            // 根因链：Display 不带内部细节，根因走 source 逐层取。
            let mut cause = error.source();
            while let Some(current) = cause {
                println!("root cause walk: {current}");
                cause = current.source();
            }
        }
    }
}
