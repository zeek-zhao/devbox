use std::mem::{offset_of, size_of};

#[repr(C)]
struct Header {
    kind: u8,
    length: u32,
}

#[repr(transparent)]
struct DocumentId(u64);

fn main() {
    println!("C header size: {}", size_of::<Header>());
    println!("length offset: {}", offset_of!(Header, length));
    println!("transparent size: {}", size_of::<DocumentId>());
}
