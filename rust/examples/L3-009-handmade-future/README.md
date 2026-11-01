# L3-009-handmade-future

## 考点
对应 KP-RS-L3-09：手写 Future 与最小 block_on。自定义 Future 被手写 poll 驱动并稳定输出 Ready 值，Pending 时等待 Waker 唤醒后重试

## 易错点
把 `Future::poll` 当成只会调用一次的同步函数，或在返回 `Pending` 后不安排唤醒，会让任务永远得不到再次执行的机会。返回 `Pending` 前必须确保相应事件到来时唤醒传入的 `Waker`；轮询还要遵守 pinning 对状态地址稳定性的要求。

## 延伸
项目的 `src/lib.rs` 是同步文件扫描和线程并行 CLI，没有异步 I/O 或 executor；`ReadyFuture` 只用于测试里演示显式 `poll`。当前项目没有真正需要手写 Future 的地方，本例只作异步运行时基础练习。

## 复现
TAG=latest scripts/run-example.sh rust L3-009-handmade-future
