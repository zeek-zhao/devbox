use std::marker::PhantomData;
use std::mem::size_of;

struct Id<T> {
    raw: u64,
    marker: PhantomData<T>,
}

fn main() {
    let user_id = Id::<String> {
        raw: 42,
        marker: PhantomData,
    };
    println!("id: {}", user_id.raw);
    println!("marker size: {}", size_of::<PhantomData<String>>());
    println!("id size: {}", size_of::<Id<String>>());
}
