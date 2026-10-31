pub fn normalize_label(label: &str) -> String {
    label.trim().to_ascii_lowercase()
}

fn internal_prefix() -> &'static str {
    "record:"
}

pub fn describe(label: &str) -> String {
    format!("{} {}", internal_prefix(), normalize_label(label))
}
