struct Record<'a> {
    name: &'a [u8],
}

fn parse(input: &[u8]) -> Option<Record<'_>> {
    let (&length, name) = input.split_first()?;
    let name = name.get(..usize::from(length))?;
    Some(Record { name })
}

fn main() {
    let input = [4, b'd', b'o', b'c', b's'];
    let record = parse(&input).expect("record is valid");
    let borrowed = std::ptr::eq(record.name.as_ptr(), input[1..].as_ptr());

    println!("borrowed input: {borrowed}");
    println!(
        "field: {}",
        std::str::from_utf8(record.name).expect("valid UTF-8")
    );
}
