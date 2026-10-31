# L1-009-result-propagation

<!-- coverage: pending -->

## 考点
对应 KP-RS-L1-09：解析和调用层均返回 `Result`，通过 `?` 将可恢复错误传到边界。
看到合法输入输出 `7`、非法输入输出 `invalid-digit`，且传播后的错误与直接解析错误相等，说明掌握错误传播。
边界匹配处理错误后继续执行，没有把非法输入变成 panic。

## 易错点
会对外部输入直接 `unwrap`，使可恢复错误变成 panic，因为解析不保证成功。
返回 `Result` 并在边界处理错误；本例的 `expect_err` 只验证固定非法测试数据，不用于接收用户输入。

## 延伸
在 CLI 参数解析层保留标准库错误，让入口统一决定错误提示和退出策略。
将文件读取失败也沿调用链返回，避免中间辅助函数擅自终止整个程序。

## 复现
TAG=latest scripts/run-example.sh rust L1-009-result-propagation
