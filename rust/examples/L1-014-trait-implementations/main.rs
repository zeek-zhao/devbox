trait Document {
    fn title(&self) -> &str;

    fn summary(&self) -> String {
        format!("document: {}", self.title())
    }
}

struct Guide {
    title: &'static str,
}

struct Note {
    title: &'static str,
}

impl Document for Guide {
    fn title(&self) -> &str {
        self.title
    }
}

impl Document for Note {
    fn title(&self) -> &str {
        self.title
    }
}

fn main() {
    let guide = Guide { title: "Setup" };
    let note = Note { title: "Search" };
    println!("{}", guide.summary());
    println!("{}", note.summary());
}
