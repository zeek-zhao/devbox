trait Label {
    fn label(&self) -> &str;
}

struct Page(&'static str);
struct Section(&'static str);

impl Label for Page {
    fn label(&self) -> &str {
        self.0
    }
}

impl Label for Section {
    fn label(&self) -> &str {
        self.0
    }
}

fn show<T: Label>(item: &T) {
    println!("item: {}", item.label());
}

fn show_pair<T, U>(first: &T, second: &U)
where
    T: Label,
    U: Label,
{
    println!("pair: {} + {}", first.label(), second.label());
}

fn main() {
    let page = Page("index");
    let section = Section("intro");
    show(&page);
    show(&section);
    show_pair(&page, &section);
}
