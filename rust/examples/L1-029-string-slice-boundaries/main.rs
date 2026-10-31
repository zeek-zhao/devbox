fn main() {
    let text = "A中B";
    assert!(text.is_char_boundary(1));
    assert!(text.is_char_boundary(4));
    let middle = &text[1..4];
    assert_eq!(middle, "中");
    println!("valid byte slice 1..4: {middle}");

    let boundaries: Vec<_> = (0..=text.len())
        .filter(|&index| text.is_char_boundary(index))
        .collect();
    assert_eq!(boundaries, vec![0, 1, 4, 5]);
    println!("valid byte boundaries: {boundaries:?}");
    for (label, range) in [
        ("character ordinal used as byte end", 1..2),
        ("start inside encoding", 2..4),
        ("past end", 4..6),
    ] {
        match text.get(range) {
            None => println!("{label}: None"),
            Some(_) => panic!("invalid range unexpectedly accepted"),
        }
    }
    let empty = text.get(4..4);
    assert_eq!(empty, Some(""));
    println!("empty slice at valid boundary: {empty:?}");
}
