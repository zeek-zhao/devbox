fn main() {
    println!("indexed count: {}", workspace_core::indexed_count());
}

#[cfg(test)]
mod tests {
    #[test]
    fn uses_workspace_library() {
        assert_eq!(workspace_core::indexed_count(), 3);
    }
}
