fn main() {
    let values = [10, 20, 30];
    let middle = &values[1..3];
    println!("slice: {middle:?}");

    match values.get(1) {
        Some(value) => println!("index 1: {value}"),
        None => println!("index 1: out of bounds"),
    }
    match values.get(8) {
        Some(value) => println!("index 8: {value}"),
        None => println!("index 8: out of bounds"),
    }
    println!("length unchanged: {}", values.len());
}
