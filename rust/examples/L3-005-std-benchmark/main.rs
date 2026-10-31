use std::time::Instant;

fn main() {
    let started = Instant::now();
    let mut checksum = 0u64;
    for value in 0..1000u64 {
        checksum += value;
    }
    let _diagnostic_elapsed = started.elapsed();

    println!("operations: 1000");
    println!("checksum: {checksum}");
}
