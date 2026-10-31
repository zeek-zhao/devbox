# L1-009-length-uppercase


## 考点
对应 KP-SH-L1-09：`${#value}` 计算字符串长度，`${value^^}` 转为大写。
看到 `ab` 输出长度 `2` 且大写结果为 `AB`，说明掌握这两种 Bash 展开。

## 易错点
`${#value}` 是字符串长度而非数组元素数；将两者混淆会得到错误判断。
大小写转换是 Bash 扩展，POSIX `sh` 不支持；需要此行为时明确用 Bash 执行。

## 延伸
用大写展开格式化状态标签，并测试已有大写字母和空字符串。
在需要 POSIX `sh` 的脚本中改用可移植工具，并明确处理字符集约定。

## 复现
TAG=latest scripts/run-example.sh shell L1-009-length-uppercase
