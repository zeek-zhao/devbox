// E-001 错误分类学：可恢复错误用 Result，不可恢复错误（不变量破坏）用 panic。
// 分类决策是错误处理的第一步：先问「这类失败能否被调用方有意义地处理」。

use std::panic;

/// 可恢复：端口来自外部配置，解析失败是预期内的输入问题，调用方可以回退默认值。
fn parse_port(raw: &str) -> Result<u16, String> {
    raw.parse::<u16>()
        .map_err(|error| format!("port.parse: {error}"))
}

/// 不可恢复：排序后仍乱序说明不变量被破坏，继续跑只会污染下游，panic 是正确出口。
fn assert_sorted(sorted: &[u32]) {
    assert!(
        sorted.windows(2).all(|pair| pair[0] <= pair[1]),
        "sort invariant violated: {sorted:?}"
    );
}

fn main() {
    // 可恢复分支：Err 被处理，程序继续。
    let fallback = parse_port("not-a-number").unwrap_or(0);
    println!("recoverable: Err -> fallback port {fallback}");

    match parse_port("8080") {
        Ok(port) => println!("recoverable: Ok -> port {port}"),
        Err(_) => println!("recoverable: Ok branch not hit"),
    }

    // 不可恢复分支：panic 在示例里用 catch_unwind 捕获取证，避免示例自身崩溃；
    // 真实代码里它应当终止当前线程/进程，而不是被捕获后当作普通错误继续。
    panic::set_hook(Box::new(|_| {}));
    let outcome = panic::catch_unwind(|| assert_sorted(&[3, 1, 2]));
    drop(panic::take_hook());
    println!(
        "unrecoverable: invariant panic caught = {}",
        outcome.is_err()
    );
    println!("taxonomy: recoverable=Result, unrecoverable=panic");
}
