# L2-004-test-coverage

<!-- coverage: pending -->

## 考点
对应 KP-GO-L2-04：通过 go test -coverprofile 和 go tool cover 查看目标函数的语句覆盖率。
看到目标函数的稳定覆盖率数值，且有一条未测试分支，说明能观察覆盖范围而非把比例当作正确性结论。

## 易错点
覆盖率高不代表断言有效；未覆盖的错误路径和边界也可能藏有缺陷。
为错误路径和边界补断言，不把百分比当正确性证明。

## 延伸
为索引器核心逻辑分别覆盖正常查询、空输入和未命中路径，并核对每条路径的断言。
进一步使用覆盖率 profile 定位未执行语句，而不是只追求整体百分比。

## 复现
TAG=latest scripts/run-example.sh go L2-004-test-coverage
