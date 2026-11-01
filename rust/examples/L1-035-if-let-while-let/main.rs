fn first_positive(values: &[i32]) -> Option<i32> {
    let [first, ..] = values else {
        return None;
    };
    Some(*first)
}

fn main() {
    let candidate = Some(7);
    if let Some(value) = candidate {
        println!("if let: {value}");
    }
    let mut values = [Some(2), Some(4), None, Some(8)].into_iter();
    while let Some(Some(value)) = values.next() {
        println!("while let: {value}");
    }
    println!("let else: {}", first_positive(&[9]).unwrap());
    println!("empty: {}", first_positive(&[]).is_none());
}
