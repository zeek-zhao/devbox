#[derive(Debug)]
enum Event {
    Retry { attempt: u8 },
}

fn main() {
    let selected = Some(Event::Retry { attempt: 2 });
    if let Some(event @ Event::Retry { attempt }) = selected {
        println!("selected {event:?}, attempt {attempt}");
    }

    let mut values = vec![4, 5, 6].into_iter();
    while let Some(value) = values.next() {
        println!("next value: {value}");
    }
}
