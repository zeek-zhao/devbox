# L3-006-signal-cleanup


## 考点
对应 KP-SH-L3-06：worker 就绪后接收 `TERM`，清理活动标记并以非零状态退出。
观察到清理完成且部署步骤被跳过，就说明信号路径没有继续执行后续工作。

## 易错点
只处理 `EXIT` 不能证明信号路径正确；TERM 后若继续执行，可能误触发部署操作。
为 `TERM` 安装明确处理器，清理后退出；用 ready 握手确认进程就绪再发送信号。

## 延伸
把清理逻辑扩展为恢复部署前写入的状态，并确保重复清理仍可安全执行。
比较 `TERM` 与不可捕获的 `KILL`，明确哪些退出路径能执行 Shell trap。

## 复现
TAG=latest scripts/run-example.sh shell L3-006-signal-cleanup
