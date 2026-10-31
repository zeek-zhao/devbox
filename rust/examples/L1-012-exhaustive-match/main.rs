enum QueryResult {
    Found { count: usize },
    Missing,
    Invalid { reason: &'static str },
}

fn describe(result: QueryResult) {
    match result {
        QueryResult::Found { count } => println!("found {count} records"),
        QueryResult::Missing => println!("no records"),
        QueryResult::Invalid { reason } => println!("invalid query: {reason}"),
    }
}

fn main() {
    describe(QueryResult::Found { count: 3 });
    describe(QueryResult::Missing);
    describe(QueryResult::Invalid {
        reason: "empty term",
    });
}
