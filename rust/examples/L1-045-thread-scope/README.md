# L1-045-thread-scope

## 考点
对应 KP-RS-L1-45：thread::scope 借用栈上数据。作用域内线程读取栈数组并在离开作用域前 join 汇总，无需 Arc

## 易错点
把普通 `thread::spawn` 的闭包直接借用栈上数据，会因线程可能比借用者活得更久而无法通过编译。`thread::scope` 保证作用域退出前线程已结束，因此可以借用局部数据；若任务要逃出当前作用域，仍需转移所有权或使用共享所有权。

## 延伸
项目的 `src/lib.rs` 在 `process_lines` 中用 `thread::scope` 启动 worker，让线程借用作用域并在结束前汇总结果。这样无需为线程生命周期额外提升借用数据的存活时间，适合这类由一次调用统一管理的并行任务。

## 复现
TAG=latest scripts/run-example.sh rust L1-045-thread-scope
