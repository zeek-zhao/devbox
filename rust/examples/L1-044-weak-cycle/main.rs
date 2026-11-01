use std::cell::RefCell;
use std::rc::{Rc, Weak};

struct Node {
    parent: RefCell<Weak<Node>>,
    children: RefCell<Vec<Rc<Node>>>,
}

fn main() {
    let child = Rc::new(Node {
        parent: RefCell::new(Weak::new()),
        children: RefCell::new(Vec::new()),
    });
    let parent = Rc::new(Node {
        parent: RefCell::new(Weak::new()),
        children: RefCell::new(Vec::new()),
    });
    parent.children.borrow_mut().push(Rc::clone(&child));
    *child.parent.borrow_mut() = Rc::downgrade(&parent);
    println!("parent strong: {}", Rc::strong_count(&parent));
    println!("child strong: {}", Rc::strong_count(&child));
    drop(parent);
    println!(
        "upgrade after drop: {}",
        child.parent.borrow().upgrade().is_some()
    );
    let weak = Rc::downgrade(&child);
    drop(child);
    println!("strong after drop: {}", weak.strong_count());
    println!("upgrade after final drop: {}", weak.upgrade().is_none());
}
