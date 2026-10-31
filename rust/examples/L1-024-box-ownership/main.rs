struct PlanNode {
    value: u32,
    next: Option<Box<PlanNode>>,
}

fn take_box(mut owned: Box<u32>) -> Box<u32> {
    *owned += 2;
    owned
}

fn main() {
    let mut boxed = Box::new(7);
    println!("boxed initial: {}", *boxed);
    *boxed += 1;
    assert_eq!(*boxed, 8);
    println!("boxed after dereference update: {}", *boxed);
    let returned = take_box(boxed);
    assert_eq!(*returned, 10);
    println!("box moved and returned: {}", *returned);

    let plan = Box::new(PlanNode {
        value: 2,
        next: Some(Box::new(PlanNode {
            value: 5,
            next: None,
        })),
    });
    let mut cursor = Some(plan);
    let mut values = Vec::new();
    while let Some(node) = cursor {
        let PlanNode { value, next } = *node;
        values.push(value);
        cursor = next;
    }
    assert_eq!(values, vec![2, 5]);
    println!("recursive nodes consumed by value: {values:?}");
}
