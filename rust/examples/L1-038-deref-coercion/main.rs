use std::ops::Deref;

struct MyBox<T>(T);

impl<T> Deref for MyBox<T> {
    type Target = T;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

fn show_text(value: &str) {
    println!("text: {value}");
}

fn main() {
    let value = MyBox(String::from("borrowed through Deref"));
    show_text(&value);
    println!("explicit: {}", *value);
}
