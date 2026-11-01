use std::borrow::Borrow;
use std::collections::HashMap;

fn byte_len<T: AsRef<str>>(value: T) -> usize {
    value.as_ref().len()
}

fn lookup<'a, Q>(map: &'a HashMap<String, usize>, key: &Q) -> Option<&'a usize>
where
    String: Borrow<Q>,
    Q: Eq + std::hash::Hash + ?Sized,
{
    map.get(key)
}

fn main() {
    let text = String::from("rust");
    println!("AsRef lengths: {} {}", byte_len("rust"), byte_len(&text));
    let counts = HashMap::from([(String::from("rust"), 4)]);
    println!("Borrow lookup: {}", lookup(&counts, "rust").unwrap());
}
