use std::thread;

fn main() {
    let values = [3, 5, 7];
    let total = thread::scope(|scope| {
        let first = scope.spawn(|| values[0] + values[1]);
        let second = scope.spawn(|| values[2]);
        first.join().unwrap() + second.join().unwrap()
    });
    println!("borrowed stack total: {total}");
}
