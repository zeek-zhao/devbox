pub fn indexed_count() -> usize {
    3
}

#[cfg(test)]
mod tests {
    #[test]
    fn reports_indexed_count() {
        assert_eq!(super::indexed_count(), 3);
    }
}
