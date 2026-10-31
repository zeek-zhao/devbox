# L2-003-bats-run-assertions

<!-- coverage: pending -->

## 考点
对应 KP-SH-L2-03：Bats 的 `run` 捕获命令输出和退出状态。
两条测试分别通过 `$status` 与 `$output` 验证成功和拒绝路径，且 TAP 报告两条 `ok`，说明断言生效。

## 易错点
`run` 捕获的状态在 Bats 的 `$status`，不应读取外层 `$?` 来判断被测命令。
分别断言 `$status` 和 `$output`，避免只验证状态却漏掉错误消息或业务结果。

## 延伸
为毕业项目的 CLI 命令添加成功、非法输入和业务拒绝等 Bats 回归测试。
将退出状态与标准输出断言分开维护，明确稳定的命令行契约。

## 复现
TAG=latest scripts/run-example.sh shell L2-003-bats-run-assertions
