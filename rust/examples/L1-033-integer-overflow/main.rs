use std::convert::TryFrom;

fn main() {
    let overflow = u8::MAX.checked_add(1);
    println!("checked overflow: {overflow:?}");

    let converted = u8::try_from(42_u16);
    match converted {
        Ok(value) => println!("narrow conversion: {value}"),
        Err(_) => println!("narrow conversion: out of range"),
    }
}
