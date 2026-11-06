// E-015 跨线程错误传播：JoinHandle 把 worker 的 Result 收回主线程；
// mpsc 把错误当值在线程间传递；Mutex 中毒后区分「锁状态」与「数据是否
// 仍可用」，必要时 into_inner 恢复。

use std::fmt;
use std::sync::mpsc;
use std::sync::{Arc, Mutex};
use std::thread;

#[derive(Debug)]
enum WorkerError {
    BadInput(u32),
}

impl fmt::Display for WorkerError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::BadInput(value) => write!(formatter, "worker got bad input {value}"),
        }
    }
}

impl std::error::Error for WorkerError {}

fn main() {
    // 静默 panic hook：本例第 3 段故意制造锁中毒，避免默认 panic 输出干扰。
    std::panic::set_hook(Box::new(|_| {}));

    // 1) JoinHandle：worker 返回 Result，join 把成功与失败都收回主线程。
    let ok_worker = thread::spawn(|| Ok::<u32, WorkerError>(42));
    let bad_worker =
        thread::spawn(|| -> Result<u32, WorkerError> { Err(WorkerError::BadInput(7)) });
    println!("join ok: {:?}", ok_worker.join());
    println!(
        "join err propagated: {}",
        match bad_worker.join() {
            Ok(Err(WorkerError::BadInput(value))) => format!("BadInput({value})"),
            _ => "unexpected".to_string(),
        }
    );

    // 2) mpsc：worker 把错误作为值发回，主线程 recv 后按需处理。
    let (sender, receiver) = mpsc::channel::<Result<u32, WorkerError>>();
    thread::spawn(move || {
        let _ = sender.send(Err(WorkerError::BadInput(9)));
    });
    println!("channel: {:?}", receiver.recv());

    // 3) Mutex 中毒：持锁线程 panic 后锁标记中毒。锁状态不等于数据损坏——
    //    increment 发生在 panic 之前，数据仍一致，into_inner 恢复是正确的。
    let counter = Arc::new(Mutex::new(0u32));
    let poisoned = Arc::clone(&counter);
    let handle = thread::spawn(move || {
        let mut guard = poisoned.lock().unwrap();
        *guard += 1;
        panic!("worker dies holding the lock");
    });
    let _ = handle.join();

    let recovered = match counter.lock() {
        Ok(guard) => *guard,
        Err(poison_error) => *poison_error.into_inner(),
    };
    println!("poison recovered: counter {recovered} (increment before panic survived)");
}
