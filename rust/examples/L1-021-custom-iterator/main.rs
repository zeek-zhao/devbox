struct DocumentIds {
    next_id: u32,
    end_exclusive: u32,
}

impl Iterator for DocumentIds {
    type Item = u32;

    fn next(&mut self) -> Option<Self::Item> {
        if self.next_id >= self.end_exclusive {
            return None;
        }
        let id = self.next_id;
        self.next_id += 1;
        Some(id)
    }
}

fn main() {
    let mut ids = DocumentIds {
        next_id: 21,
        end_exclusive: 24,
    };
    let collected: Vec<_> = ids.by_ref().collect();
    assert_eq!(collected, vec![21, 22, 23]);
    println!("document ids: {collected:?}");
    for attempt in 1..=3 {
        let exhausted = ids.next().is_none();
        assert!(exhausted);
        println!("exhausted call {attempt}: {exhausted}");
    }
    let mut empty = DocumentIds {
        next_id: 5,
        end_exclusive: 5,
    };
    assert_eq!(empty.next(), None);
    println!("empty range: {:?}", empty.next());
}
