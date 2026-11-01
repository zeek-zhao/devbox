use std::slice;

unsafe fn sum_raw_parts(pointer: *const u8, length: usize) -> u8 {
    // SAFETY: the caller provides a non-null aligned pointer to one live allocation of initialized bytes.
    let bytes = unsafe { slice::from_raw_parts(pointer, length) };
    bytes.iter().copied().sum()
}

fn main() {
    let bytes = [2_u8, 3, 5];
    // SAFETY: `bytes` is a live array and its pointer is valid for its full length.
    let total = unsafe { sum_raw_parts(bytes.as_ptr(), bytes.len()) };
    println!("sum: {total}");
    println!("input length: {}", bytes.len());
}
