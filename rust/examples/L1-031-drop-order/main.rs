struct Marker(&'static str);

impl Drop for Marker {
    fn drop(&mut self) {
        println!("drop: {}", self.0);
    }
}

fn main() {
    {
        let _first = Marker("first");
        println!("created: first");
        let _second = Marker("second");
        println!("created: second");
    }
}
