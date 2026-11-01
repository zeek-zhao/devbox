/// Returns the normalized document count.
///
/// See [`DocumentCount`] for the value type.
pub fn count() -> DocumentCount {
    DocumentCount(3)
}

/// Count of documents accepted by the index.
pub struct DocumentCount(pub usize);

fn main() {
    println!("document count: {}", count().0);
}
