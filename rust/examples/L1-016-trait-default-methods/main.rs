trait Summary {
    fn title(&self) -> &str;

    fn summary(&self) -> String {
        format!("summary: {}", self.title())
    }
}

struct PlainDocument(&'static str);
struct CompactDocument(&'static str);

impl Summary for PlainDocument {
    fn title(&self) -> &str {
        self.0
    }
}

impl Summary for CompactDocument {
    fn title(&self) -> &str {
        self.0
    }

    fn summary(&self) -> String {
        format!("compact: {}", self.title())
    }
}

fn main() {
    let plain = PlainDocument("Guide");
    let compact = CompactDocument("Guide");
    println!("{}", plain.summary());
    println!("{}", compact.summary());
}
