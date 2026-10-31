#[test]
fn describes_a_normalized_label_through_the_public_api() {
    assert_eq!(
        integration_tests::describe(" READY "),
        "record: ready"
    );
}
