fn read_query(query: &str) {
    println!("borrowed query: {query}");
}

fn take_query(mut query: String) {
    query.push_str(" index");
    assert_eq!(query, "rust index");
    println!("callee owns query: {query}");
}

fn main() {
    let query = String::from("rust");
    read_query(&query);
    println!("caller after borrow: {query}");
    take_query(query);
    // query 已移动；这里不再访问它，所有者是 take_query 的参数。
    println!("caller after move: ownership transferred");
}
