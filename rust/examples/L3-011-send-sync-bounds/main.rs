use std::rc::Rc;
use std::thread;

fn require_send_sync<T: Send + Sync>() {}

fn main() {
    require_send_sync::<String>();
    let value = String::from("sent to worker");
    let result = thread::spawn(move || value.len()).join().unwrap();
    println!("String is Send + Sync; worker length: {result}");
    println!(
        "Rc is single-threaded: {}",
        Rc::strong_count(&Rc::new(1)) == 1
    );
}
