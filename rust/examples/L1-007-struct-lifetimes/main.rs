struct DocumentView<'a> {
    title: &'a str,
    body: &'a str,
}

fn main() {
    let title = String::from("guide");
    let body = String::from("rust ownership");
    {
        let record = DocumentView {
            title: &title,
            body: &body,
        };
        assert_eq!(record.title, "guide");
        assert_eq!(record.body, "rust ownership");
        println!("record title: {}", record.title);
        println!("record body: {}", record.body);
    }
    println!("title owner after view: {title}");
    println!("body owner after view: {body}");
}
