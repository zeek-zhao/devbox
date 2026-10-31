use std::cell::RefCell;
use std::rc::Rc;

fn main() {
    let cache = Rc::new(RefCell::new(10));
    assert_eq!(Rc::strong_count(&cache), 1);
    println!("initial owners: {}", Rc::strong_count(&cache));
    {
        let reader = Rc::clone(&cache);
        assert_eq!(Rc::strong_count(&cache), 2);
        println!("shared owners: {}", Rc::strong_count(&cache));
        {
            let read_guard = reader.borrow();
            let conflict_rejected = cache.try_borrow_mut().is_err();
            assert!(conflict_rejected);
            println!("value under shared borrow: {}", *read_guard);
            println!("overlapping mutable borrow rejected: {conflict_rejected}");
        }
        {
            let mut write_guard = cache.borrow_mut();
            *write_guard += 5;
        }
        assert_eq!(*cache.borrow(), 15);
        assert_eq!(*reader.borrow(), 15);
        println!("original owner reads: {}", *cache.borrow());
        println!("shared owner reads: {}", *reader.borrow());
    }
    assert_eq!(Rc::strong_count(&cache), 1);
    println!(
        "owners after shared handle leaves: {}",
        Rc::strong_count(&cache)
    );
}
