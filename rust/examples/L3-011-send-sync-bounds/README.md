# L3-011-send-sync-bounds

## 考点
对应 KP-RS-L3-11：Send/Sync 泛型约束与 spawn。String 满足 Send + Sync 并可移入线程；另一个编译负例证明 Rc 不能安全跨线程

## 易错点
类型能在线程间移动（`Send`），不等于能被多个线程同时共享引用（`Sync`）；把含 `Rc` 的值移进 `thread::spawn` 会因缺少线程安全约束而无法编译。跨线程共享时选择满足 `Send`/`Sync` 的数据或用 `Arc` 等同步原语保护它，不要靠强制标记 trait 绕过检查。

## 延伸
项目的 `src/lib.rs` 在 `process_lines` 中把拥有型分片移入 scoped worker，并用 `Arc<Mutex<usize>>` 共享完成计数；`String` 满足线程移动所需的 `Send`。生产路径的线程边界必须由这些 trait 和同步原语保证安全，不能换成 `Rc<RefCell<_>>`。

## 复现
TAG=latest scripts/run-example.sh rust L3-011-send-sync-bounds
