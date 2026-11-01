fn sum<const N: usize>(values: [i32; N]) -> i32 {
    values.into_iter().sum()
}

fn describe<const N: usize>(values: &[i32; N]) {
    println!("length: {N}, sum: {}", sum(*values));
}

fn main() {
    describe(&[2, 3, 5]);
    describe(&[10, 20]);
}
