# L2-005-assert-harness

<!-- coverage: pending -->

## 考点
对应 KP-JV-L2-05：手写 harness 用 assert 检查，并把失败汇总为非零退出。
看到 -ea 正常测试全过、注入失败计数增加且退出非零、未启用断言被拒绝，即掌握验收边界。

## 易错点
失败测试会假通过，因为 assert 默认关闭或只打印失败未改退出码。
启动时用 desiredAssertionStatus 检查开关，逐项记录失败，并在任一失败时返回非零。

## 延伸
为文档索引器的正常、边界与错误输入建立独立测试项并汇总结果。
进一步用进程级测试验证命令退出码与 stdout、stderr 协议。

## 复现
TAG=latest scripts/run-example.sh java L2-005-assert-harness
