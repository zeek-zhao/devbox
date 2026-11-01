use std::alloc::{GlobalAlloc, Layout, System};
use std::sync::atomic::{AtomicUsize, Ordering};

struct CountingAllocator;
static GROWTHS: AtomicUsize = AtomicUsize::new(0);

unsafe impl GlobalAlloc for CountingAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        // SAFETY: forwarding the unchanged layout to the system allocator.
        unsafe { System.alloc(layout) }
    }
    unsafe fn dealloc(&self, pointer: *mut u8, layout: Layout) {
        // SAFETY: pointer and layout came from the system allocator.
        unsafe { System.dealloc(pointer, layout) }
    }
    unsafe fn realloc(&self, pointer: *mut u8, layout: Layout, size: usize) -> *mut u8 {
        GROWTHS.fetch_add(1, Ordering::Relaxed);
        // SAFETY: pointer and layout came from the system allocator.
        unsafe { System.realloc(pointer, layout, size) }
    }
}

#[global_allocator]
static ALLOCATOR: CountingAllocator = CountingAllocator;

fn main() {
    let mut values = Vec::with_capacity(1);
    values.push(10);
    let before = GROWTHS.load(Ordering::Relaxed);
    values.push(20);
    let growths = GROWTHS.load(Ordering::Relaxed) - before;
    println!("length: {}", values.len());
    println!("capacity grew: {}", values.capacity() > 1);
    println!("reallocations for growth: {growths}");
}
