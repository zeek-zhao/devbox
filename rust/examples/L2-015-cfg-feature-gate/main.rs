#[cfg_attr(feature = "trace", derive(Debug))]
struct Mode;

fn main() {
    #[cfg(feature = "trace")]
    println!("feature: trace {:?}", Mode);
    #[cfg(not(feature = "trace"))]
    {
        let _mode = Mode;
        println!("feature: default");
    }
}
