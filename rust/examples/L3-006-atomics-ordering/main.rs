use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::Mutex;
use std::thread;

fn main() {
    let count = AtomicUsize::new(0);
    let ready = AtomicBool::new(false);
    let data = Mutex::new(None);

    let (operations, published) = thread::scope(|scope| {
        scope.spawn(|| {
            for _ in 0..3 {
                count.fetch_add(1, Ordering::SeqCst);
            }
            *data.lock().unwrap() = Some(42);
            ready.store(true, Ordering::Release);
        });

        while !ready.load(Ordering::Acquire) {
            thread::yield_now();
        }
        (count.load(Ordering::SeqCst), *data.lock().unwrap())
    });

    println!("atomic operations: {operations}");
    println!(
        "mutex-protected data: {}",
        published.expect("published data is present")
    );
}
