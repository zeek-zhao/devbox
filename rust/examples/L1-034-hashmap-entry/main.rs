use std::collections::{BTreeMap, HashMap};

fn main() {
    let mut fast = HashMap::new();
    *fast.entry("pear").or_insert(0) += 1;
    *fast.entry("apple").or_insert(0) += 1;
    *fast.entry("pear").or_insert(0) += 1;
    let mut sorted = fast.into_iter().collect::<Vec<_>>();
    sorted.sort_by(|left, right| left.0.cmp(&right.0));
    for (key, value) in sorted {
        println!("{key}: {value}");
    }
    let ordered = BTreeMap::from([("pear", 2), ("apple", 1)]);
    println!("BTreeMap first: {}", ordered.keys().next().unwrap());
}
