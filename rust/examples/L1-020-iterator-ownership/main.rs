fn main() {
    let mut terms = vec![String::from("rust"), String::from("search")];

    for term in terms.iter() {
        println!("borrowed: {term}");
    }
    println!("still available: {}", terms.len());

    for term in terms.iter_mut() {
        term.make_ascii_uppercase();
    }
    println!("after mutable borrow: {terms:?}");

    let owned_terms = terms.into_iter();
    for term in owned_terms {
        println!("owned: {term}");
    }
}
