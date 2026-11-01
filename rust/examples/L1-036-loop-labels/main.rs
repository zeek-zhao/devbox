fn find_target(grid: &[[i32; 3]; 3], target: i32) -> Option<(usize, usize)> {
    'rows: loop {
        for (row_index, row) in grid.iter().enumerate() {
            for (column_index, value) in row.iter().enumerate() {
                if *value == target {
                    break 'rows Some((row_index, column_index));
                }
            }
        }
        break 'rows None;
    }
}

fn main() {
    let grid = [[1, 2, 3], [4, 5, 6], [7, 8, 9]];
    let mut targets = [0, 6].into_iter();
    let location = 'search: loop {
        let Some(target) = targets.next() else {
            break 'search None;
        };
        for (row, values) in grid.iter().enumerate() {
            for (column, value) in values.iter().enumerate() {
                if *value == target {
                    break 'search Some((row, column));
                }
            }
        }
    };
    println!("loop result: {location:?}");
    println!("function result: {:?}", find_target(&grid, 8));
}
