# L1-044-weak-cycle

## 考点
对应 KP-RS-L1-44：Weak 打破 Rc 引用循环。强引用计数不被弱父子边增加，目标销毁后 weak upgrade 为 None

## 易错点
父子节点互相保存 `Rc` 强引用会形成引用环，即使外部不再使用节点，强引用计数也不会归零。把非所有权的回指改成 `Weak`，访问前用 `upgrade` 检查目标是否还活着，并接受目标销毁后得到 `None`。

## 延伸
项目的 `src/lib.rs` 用 `Arc`、`Mutex` 和线程通道管理 worker 状态，没有构造 `Rc` 父子图或回指关系。当前 CLI 没有需要用 `Weak` 打破引用环的地方，本例只作共享所有权生命周期练习。

## 复现
TAG=latest scripts/run-example.sh rust L1-044-weak-cycle
