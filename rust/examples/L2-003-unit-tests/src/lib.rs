pub fn is_even(value: u32) -> bool {
    value % 2 == 0
}

pub fn require_nonzero(value: u32) {
    assert_ne!(value, 0, "value must be nonzero");
}

#[cfg(test)]
mod tests {
    use super::{is_even, require_nonzero};

    #[test]
    fn recognizes_even_values() {
        assert!(is_even(8));
        assert!(!is_even(7));
    }

    #[test]
    #[should_panic(expected = "value must be nonzero")]
    fn rejects_zero() {
        require_nonzero(0);
    }
}
