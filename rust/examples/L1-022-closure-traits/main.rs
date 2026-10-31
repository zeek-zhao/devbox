fn read_twice<F: Fn() -> usize>(read: F) -> [usize; 2] {
    [read(), read()]
}

fn update_twice<F: FnMut() -> u32>(mut update: F) -> [u32; 2] {
    [update(), update()]
}

fn consume_once<F: FnOnce() -> String>(consume: F) -> String {
    consume()
}

fn main() {
    let query = String::from("rust");
    let lengths = read_twice(|| query.len());
    assert_eq!(lengths, [4, 4]);
    println!("Fn repeated lengths: {lengths:?}");
    println!("borrowed query remains: {query}");

    let mut count = 0;
    let updates = update_twice(|| {
        count += 1;
        count
    });
    assert_eq!(updates, [1, 2]);
    assert_eq!(count, 2);
    println!("FnMut updates: {updates:?}");
    println!("captured count after calls: {count}");

    let owned = String::from("consumed query");
    let consume = || owned;
    let returned = consume_once(consume);
    assert_eq!(returned, "consumed query");
    println!("FnOnce transferred value: {returned}");
}
