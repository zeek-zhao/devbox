fn main() {
    println!("runtime has no dev-only dependency");
}

#[cfg(test)]
mod tests {
    #[test]
    fn dev_dependency_is_visible_to_tests() {
        assert_eq!(dev_support::marker(), "test-only");
    }
}
