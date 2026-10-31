mod query {
    mod parser {
        fn normalize(input: &str) -> &str {
            input.trim()
        }

        pub(super) fn parse(input: &str) -> &str {
            normalize(input)
        }
    }

    pub fn search(input: &str) -> String {
        let term = self::parser::parse(input);
        format!("query:{term}")
    }

    pub(crate) fn api_name() -> &'static str {
        "query"
    }
}

use crate::query::search;

fn main() {
    let full_path = crate::query::search("  rust  ");
    let imported = search("  rust  ");
    assert_eq!(full_path, "query:rust");
    assert_eq!(full_path, imported);
    assert_eq!(query::api_name(), "query");
    println!("public API via full path: {full_path}");
    println!("public API via use: {imported}");
    println!("full and imported paths agree: {}", full_path == imported);
    println!("crate-visible API name: {}", query::api_name());
}
