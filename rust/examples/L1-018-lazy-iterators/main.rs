use std::cell::Cell;

fn main() {
    let calls = Cell::new(0);
    let mapped = [2, 4, 6].iter().map(|value| {
        calls.set(calls.get() + 1);
        value * 10
    });

    println!("before consume: {}", calls.get());
    let values: Vec<_> = mapped.collect();
    println!("after consume: {}", calls.get());
    println!("values: {values:?}");
}
