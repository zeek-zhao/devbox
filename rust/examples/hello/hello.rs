// 用例 hello：确认 rustc 可用，迭代器与所有权基本操作正常
fn main() {
    println!("[hello] Rust from devbox");

    // 区间迭代器 + 类型标注求和，确认标准库泛型推导正常
    let sum: u32 = (1..=100).sum();
    println!("sum(1..=100) = {}", sum);

    // String 与 &str 的所有权转换，这是 L1 的第一道坎
    let s = String::from("devbox");
    println!("chars = {}", s.chars().count());
}
