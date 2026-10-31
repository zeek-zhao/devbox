fn main() {
    let text = "A中🦀";
    let scalar_count = text.chars().count();
    let byte_count = text.bytes().count();
    let scalars: Vec<_> = text.chars().collect();
    let bytes: Vec<_> = text.bytes().collect();
    assert_eq!(scalar_count, 3);
    assert_eq!(byte_count, 8);
    assert_eq!(text.len(), byte_count);
    assert_eq!(scalars, vec!['A', '中', '🦀']);
    assert_eq!(bytes, vec![65, 228, 184, 173, 240, 159, 166, 128]);
    println!("text: {text}");
    println!("Unicode scalar count: {scalar_count}");
    println!("UTF-8 byte count: {byte_count}");
    println!("str len is byte count: {}", text.len() == byte_count);
    println!("chars: {scalars:?}");
    println!("bytes: {bytes:?}");

    let combining = "e\u{301}";
    assert_eq!(combining.chars().count(), 2);
    assert_eq!(combining.bytes().count(), 3);
    println!("combining text scalar count: {}", combining.chars().count());
    println!("combining text byte count: {}", combining.bytes().count());
}
