// E-012 错误可观测性：业务输出走 stdout，分级诊断（WARN/ERROR）走 stderr，
// 失败计数在收尾汇总。stdout 保持干净，stderr 行有固定锚点便于 grep。

use std::num::ParseIntError;

#[derive(Debug, Default)]
struct Metrics {
    processed: u32,
    warned: u32,
    failed: u32,
}

impl Metrics {
    fn warn(&mut self, event: &str) {
        self.warned += 1;
        eprintln!("[WARN] {event}");
    }

    fn error(&mut self, event: &str) {
        self.failed += 1;
        eprintln!("[ERROR] {event}");
    }
}

fn parse_id(raw: &str) -> Result<u32, ParseIntError> {
    raw.parse()
}

fn main() {
    let rows = ["1", "2", "bad", "4", "worse"];
    let mut metrics = Metrics::default();
    let mut degraded = false;

    for (index, row) in rows.iter().enumerate() {
        match parse_id(row) {
            Ok(id) => {
                metrics.processed += 1;
                println!("row {index}: id {id}");
            }
            Err(error) => {
                // 首次失败降级为 WARN（默认值兜底继续跑），
                // 再次失败升级为 ERROR（降级策略已失效）。
                if !degraded {
                    degraded = true;
                    metrics.warn(&format!(
                        "row {index}: parse failed ({error}), degrading to id 0"
                    ));
                    println!("row {index}: id 0");
                } else {
                    metrics.error(&format!("row {index}: parse failed ({error})"));
                }
            }
        }
    }

    println!(
        "metrics: processed={} warned={} failed={}",
        metrics.processed, metrics.warned, metrics.failed
    );
}
