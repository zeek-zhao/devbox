fn query_text(input: &str) -> &str {
    input.trim()
}

fn make_query() -> String {
    let mut query = String::from("owned");
    query.push_str(" query");
    query
}

fn main() {
    let literal = query_text("  literal  ");
    assert_eq!(literal, "literal");
    println!("literal via str: {literal}");

    let mut owned = String::from("  rust  ");
    {
        let view = query_text(&owned);
        assert_eq!(view, "rust");
        println!("String via borrowed str: {view}");
    }
    assert_eq!(owned, "  rust  ");
    println!("owner unchanged after call: {owned:?}");
    owned.push_str("query");
    assert_eq!(owned, "  rust  query");
    println!("owner can grow after borrow: {owned:?}");

    let returned = make_query();
    assert_eq!(returned, "owned query");
    println!("owned return survives function: {returned}");
}
