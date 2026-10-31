fn main() {
    let selected: Vec<i32> = [1, 2, 3, 4, 5]
        .into_iter()
        .map(|value| value * 2)
        .filter(|value| value % 4 == 0)
        .collect();
    let total = selected.iter().fold(0, |sum, value| sum + value);

    println!("selected: {selected:?}");
    println!("total: {total}");
}
