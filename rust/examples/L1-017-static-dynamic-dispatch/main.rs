trait Render {
    fn render(&self) -> &'static str;
}

struct Html;
struct Text;

impl Render for Html {
    fn render(&self) -> &'static str {
        "html"
    }
}

impl Render for Text {
    fn render(&self) -> &'static str {
        "text"
    }
}

fn render_static<T: Render>(item: &T) {
    println!("static: {}", item.render());
}

fn render_dynamic(item: &dyn Render) {
    println!("dynamic: {}", item.render());
}

fn main() {
    let html = Html;
    let text = Text;
    render_static(&html);
    render_static(&text);

    let renderers: [&dyn Render; 2] = [&html, &text];
    for renderer in renderers {
        render_dynamic(renderer);
    }
}
