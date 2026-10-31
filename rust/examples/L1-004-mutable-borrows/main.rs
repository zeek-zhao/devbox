fn append_entry(index: &mut String) {
    index.push_str("|doc2");
}

fn main() {
    let mut index = String::from("doc1");
    {
        let writer: &mut String = &mut index;
        append_entry(writer);
        println!("exclusive writer: {writer}");
    }
    {
        let reader: &str = &index;
        assert_eq!(reader, "doc1|doc2");
        println!("reader after writer: {reader}");
    }
    {
        let next_writer: &mut String = &mut index;
        next_writer.push_str("|doc3");
    }
    assert_eq!(index, "doc1|doc2|doc3");
    println!("owner after writes: {index}");
}
