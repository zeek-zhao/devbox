/// Adds one to a value.
///
/// ```
/// assert_eq!(doctests::add_one(4), 5);
/// ```
///
/// Values above the supported range are rejected at compile time.
///
/// ```compile_fail
/// let _: u8 = doctests::add_one(4);
/// ```
pub fn add_one(value: u32) -> u32 {
    value + 1
}
