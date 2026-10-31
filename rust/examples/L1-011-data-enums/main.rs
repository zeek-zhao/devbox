#[derive(Debug)]
enum TaskState {
    Queued { id: u32 },
    Running { id: u32, attempt: u8 },
}

fn main() {
    let queued = TaskState::Queued { id: 41 };
    let running = TaskState::Running { id: 42, attempt: 2 };

    match queued {
        TaskState::Queued { id } => println!("queued task: {id}"),
        TaskState::Running { id, attempt } => {
            println!("running task: {id}, attempt {attempt}")
        }
    }

    match running {
        TaskState::Queued { id } => println!("queued task: {id}"),
        TaskState::Running { id, attempt } => {
            println!("running task: {id}, attempt {attempt}")
        }
    }
}
