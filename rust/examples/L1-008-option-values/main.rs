fn show_hit(hit: Option<u32>) {
    match hit {
        Some(document_id) => {
            assert_eq!(document_id, 7);
            println!("query hit: {document_id}");
        }
        None => println!("query hit: missing"),
    }
}

fn main() {
    show_hit(Some(7));
    show_hit(None);
    let optional_limit: Option<u32> = None;
    let limit = optional_limit.unwrap_or(10);
    assert_eq!(limit, 10);
    println!("missing limit default: {limit}");
}
