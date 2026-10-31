fn main() {
    let mut buffer = String::from("query");
    let parsed: &str = &buffer;
    println!("last read: {parsed}");
    // parsed 的最后一次使用已结束，无须等到 main 的花括号末尾。
    buffer.push_str(" ready");
    assert_eq!(buffer, "query ready");
    println!("reused buffer: {buffer}");
}
