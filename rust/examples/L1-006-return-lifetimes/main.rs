fn shorter<'a>(left: &'a str, right: &'a str) -> &'a str {
    if left.len() <= right.len() {
        left
    } else {
        right
    }
}

fn main() {
    let document = String::from("rust guide");
    {
        let query = String::from("rust");
        let selected = shorter(&document, &query);
        assert_eq!(selected, query.as_str());
        println!("shorter from right: {selected}");
        let reversed = shorter(&query, &document);
        assert_eq!(reversed, query.as_str());
        println!("shorter from left: {reversed}");
    }
    println!("outer input still alive: {document}");
}
