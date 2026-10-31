fn main() {
    let mut limit = 3_u32;
    let captured_limit = move || limit;
    limit = 8;
    assert_eq!(captured_limit(), 3);
    assert_eq!(limit, 8);
    println!("Copy captured limit: {}", captured_limit());
    println!("outer limit after change: {limit}");

    let query = String::from("owned query");
    let task = move || query;
    let returned = task();
    assert_eq!(returned, "owned query");
    println!("String returned from owning closure: {returned}");

    let mut shared_query = String::from("borrowed");
    {
        let borrowed = &shared_query;
        let read = move || borrowed.as_str();
        assert_eq!(read(), "borrowed");
        println!("explicit reference captured: {}", read());
        println!("outer String still readable: {shared_query}");
    }
    shared_query.push_str(" query");
    assert_eq!(shared_query, "borrowed query");
    println!("outer String after borrow ends: {shared_query}");
}
