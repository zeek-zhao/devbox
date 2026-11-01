use std::cell::{Cell, RefCell};

fn main() {
    let counter = Cell::new(1);
    let previous = counter.get();
    counter.set(previous + 1);
    println!("Cell: {previous} -> {}", counter.get());
    let value = RefCell::new(5);
    let borrowed = value.borrow();
    println!(
        "RefCell conflict detected: {}",
        value.try_borrow_mut().is_err()
    );
    drop(borrowed);
    *value.borrow_mut() += 1;
    println!("RefCell after mutable borrow: {}", value.borrow());
}
