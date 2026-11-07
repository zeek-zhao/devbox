// E-013 优雅降级：主路径失败走备用路径，再失败走默认值；每一级降级
// 都在结果里留下来源标签——降级不是吞错，而是可追溯的兜底。

use std::num::ParseIntError;

/// 一级：主数据源，要求原始串可直接解析。
fn primary(raw: &str) -> Result<u32, ParseIntError> {
    raw.parse()
}

/// 二级：备用数据源，容许首尾空白。
fn replica(raw: &str) -> Result<u32, ParseIntError> {
    raw.trim().parse()
}

/// 三级：本地默认值。返回值携带来源标签，降级路径可追溯。
fn resolve(raw: &str) -> (u32, &'static str) {
    if let Ok(value) = primary(raw) {
        return (value, "primary");
    }
    if let Ok(value) = replica(raw) {
        return (value, "replica");
    }
    (0, "default")
}

fn main() {
    let queries = ["42", " 7 ", "gone"];
    for query in queries {
        let (value, source) = resolve(query);
        println!("query `{query}` -> {value} via {source}");
    }

    // 标准库的降级惯用法：unwrap_or_else 只在失败时计算默认值。
    let via_else = primary("gone").unwrap_or_else(|_| 0);
    println!("unwrap_or_else default: {via_else}");
}
