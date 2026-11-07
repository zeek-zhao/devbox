// E-003 unwrap/expect 治理：unwrap 只允许出现在「前提由测试钉死」的位置；
// 边界代码一律 expect（带上下文）或 `?` 上抛。本例用子进程模式取证 unwrap
// 的失败形态：退出码 101、消息无业务上下文。

use std::num::ParseIntError;

/// 治理后的写法 A：expect 带语境，panic 消息能直接指认哪条前提被打破。
/// 前提由单元测试钉死（"8080" 必然可解析），这里 unwrap 的代价才可接受。
fn fixture_port() -> u16 {
    "8080"
        .parse()
        .expect("fixture port is pinned by unit tests, parse cannot fail")
}

/// 治理后的写法 B：外部输入走 Result，由调用方决定回退，不用 panic。
fn config_port(raw: &str) -> Result<u16, ParseIntError> {
    raw.parse()
}

fn main() {
    let mode = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "good".to_string());
    match mode.as_str() {
        "good" => {
            let port = fixture_port();
            let fallback = config_port("not-a-number").unwrap_or(0);
            println!("expect-mode: fixture port {port} (context attached)");
            println!("handled-mode: invalid config -> fallback {fallback}, exit stays 0");
        }
        // 反面教材：对不可信输入 unwrap。仅由 run.sh 以子进程方式触发取证，
        // 不是可效仿的写法：panic 消息里没有任何业务上下文。
        "unwrap-bad" => {
            let _port: u16 = config_port("not-a-number").unwrap();
            println!("unreachable: unwrap above panics first");
        }
        other => println!("unknown mode: {other}"),
    }
}
