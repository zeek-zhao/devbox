fn copy_value<T: Copy>(value: T) -> T {
    value
}

fn main() {
    let document_id: u32 = 7;
    let assigned = document_id;
    let mut copied = copy_value(document_id);
    assert_eq!(document_id, assigned);
    assert_eq!(document_id, copied);
    println!("original id: {document_id}");
    println!("assigned id: {assigned}");
    println!("copied id: {copied}");

    copied += 1;
    assert_eq!(document_id, 7);
    println!("changed copy: {copied}");
    println!("original unchanged: {}", document_id == 7);

    let title = String::from("guide");
    let moved_title = title;
    println!("moved title owner: {moved_title}");
}
