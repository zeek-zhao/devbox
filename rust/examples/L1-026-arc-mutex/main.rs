use std::sync::{Arc, Mutex, TryLockError};
use std::thread;

fn add(counter: &Mutex<u32>, amount: u32) -> Result<(), &'static str> {
    let mut guard = counter.lock().map_err(|_| "counter lock poisoned")?;
    *guard += amount;
    Ok(())
}

fn main() -> Result<(), &'static str> {
    let counter = Arc::new(Mutex::new(0));
    {
        let guard = counter.lock().map_err(|_| "counter lock poisoned")?;
        let relock_blocked = match counter.try_lock() {
            Err(TryLockError::WouldBlock) => true,
            Err(TryLockError::Poisoned(_)) => return Err("counter lock poisoned"),
            Ok(_) => return Err("mutex unexpectedly allowed overlapping locks"),
        };
        assert_eq!(*guard, 0);
        println!("relock while held would block: {relock_blocked}");
    }

    let mut workers = Vec::new();
    for _ in 0..4 {
        let shared = Arc::clone(&counter);
        workers.push(thread::spawn(move || {
            for _ in 0..25 {
                add(&shared, 1)?;
            }
            Ok::<(), &'static str>(())
        }));
    }
    for worker in workers {
        worker.join().map_err(|_| "counter worker panicked")??;
    }
    let final_count = {
        let guard = counter.lock().map_err(|_| "counter lock poisoned")?;
        *guard
    };
    assert_eq!(final_count, 100);
    assert_eq!(Arc::strong_count(&counter), 1);
    println!("joined workers: 4");
    println!("shared count after unlock: {final_count}");
    println!("owners after join: {}", Arc::strong_count(&counter));
    Ok(())
}
