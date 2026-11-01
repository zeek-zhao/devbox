#[derive(Debug, Default)]
struct Settings {
    retries: u8,
    label: String,
    enabled: bool,
}

fn main() {
    let defaults = Settings::default();
    let custom = Settings {
        retries: 3,
        label: String::from("index"),
        ..Settings::default()
    };
    println!(
        "default: {} {} {}",
        defaults.retries,
        defaults.label.is_empty(),
        defaults.enabled
    );
    println!(
        "custom: {} {} {}",
        custom.retries, custom.label, custom.enabled
    );
}
