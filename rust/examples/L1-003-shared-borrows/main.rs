fn main() {
    let mut query = String::from("rust");
    {
        let first: &str = &query;
        let second: &str = &query;
        println!("first reader: {first}");
        println!("second reader: {second}");
        assert_eq!(first, second);
        println!("readers agree: {}", first == second);
        println!("owner during reads: {query}");
    }
    query.push_str(" docs");
    assert_eq!(query, "rust docs");
    println!("owner after readers: {query}");
}
