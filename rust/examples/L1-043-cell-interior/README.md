# L1-043-cell-interior

## 考点
对应 KP-RS-L1-43：Cell 与 RefCell 内部可变性。Cell 复制值后更新，RefCell 在冲突借用时返回错误而非隐藏冲突

## 易错点
把 `RefCell::borrow_mut()` 当成总能成功的普通可变借用，会在同一值已有活动借用时触发运行时 panic。可在冲突可能发生时用 `try_borrow_mut` 处理失败，并让借用尽早结束；`Cell` 适合可复制的小值，不提供 `RefCell` 那种借用守卫。

## 延伸
项目的 `src/lib.rs` 用 `Arc<Mutex<usize>>` 在 worker 线程间共享完成计数，而不是使用 `Cell` 或 `RefCell`。线程共享状态需要同步与线程安全约束，单线程内部可变性类型不能替代这个 `Mutex`。

## 复现
TAG=latest scripts/run-example.sh rust L1-043-cell-interior
