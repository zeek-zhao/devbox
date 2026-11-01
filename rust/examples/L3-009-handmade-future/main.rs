use std::future::Future;
use std::pin::pin;
use std::sync::Arc;
use std::task::{Context, Poll, Wake, Waker};
use std::thread;

struct ReadyValue(u32);

impl Future for ReadyValue {
    type Output = u32;
    fn poll(self: std::pin::Pin<&mut Self>, _context: &mut Context<'_>) -> Poll<Self::Output> {
        Poll::Ready(self.get_mut().0)
    }
}

struct ThreadWake(thread::Thread);
impl Wake for ThreadWake {
    fn wake(self: Arc<Self>) {
        self.0.unpark();
    }
}

fn block_on<F: Future>(future: F) -> F::Output {
    let waker = Waker::from(Arc::new(ThreadWake(thread::current())));
    let mut context = Context::from_waker(&waker);
    let mut future = pin!(future);
    loop {
        match future.as_mut().poll(&mut context) {
            Poll::Ready(value) => return value,
            Poll::Pending => thread::park(),
        }
    }
}

fn main() {
    println!("future output: {}", block_on(ReadyValue(42)));
}
