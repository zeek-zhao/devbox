use std::sync::{mpsc, Arc, Mutex};
use std::thread;

fn main() {
    let groups = [[1, 2], [3, 4], [5, 6]];
    let shared_total = Arc::new(Mutex::new(0usize));
    let (sender, receiver) = mpsc::channel();

    thread::scope(|scope| {
        for (id, values) in groups.iter().enumerate() {
            let sender = &sender;
            let shared_total = &shared_total;
            scope.spawn(move || {
                let subtotal: usize = values.iter().sum();
                *shared_total.lock().unwrap() += subtotal;
                sender.send((id, subtotal)).unwrap();
            });
        }
    });
    drop(sender);
    let mut results = receiver.into_iter().collect::<Vec<_>>();

    results.sort_by_key(|(id, _)| *id);
    for (id, subtotal) in results {
        println!("task {id}: {subtotal}");
    }
    println!("shared total: {}", *shared_total.lock().unwrap());
}
