use std::ffi::c_int;

unsafe extern "C" {
    fn byte_sum(data: *const u8, len: usize) -> c_int;
}

fn safe_byte_sum(data: Option<&[u8]>) -> Option<c_int> {
    let data = data?;
    Some(unsafe { byte_sum(data.as_ptr(), data.len()) })
}

fn main() {
    let data = [1, 2, 3];
    println!("byte sum: {}", safe_byte_sum(Some(&data)).expect("slice is present"));
    println!("null rejected: {}", safe_byte_sum(None).is_none());
}
