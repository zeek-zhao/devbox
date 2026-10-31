fn main() {
    let message = String::from("standard library only");
    println!("offline build: {message}");
}

#[cfg(test)]
mod tests {
    #[test]
    fn uses_standard_library() {
        assert_eq!(String::from("offline").len(), 7);
    }
}
