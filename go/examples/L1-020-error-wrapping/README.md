# L1-020-error-wrapping

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-20：用 %w 保留错误链，用 errors.Is 和 errors.As 查询原因。
看到包装后命中哨兵、取出 ReadError 的 guide.txt，而纯文本格式化两项均为 false，即掌握链查询。

## 易错点
使用 %v 只格式化文本、不保留链，提示相同也不能据此检查原因。
需要可检查原因时用 %w，并通过标准 errors API 判断；自定义包装类型实现 Unwrap。

## 延伸
为文件读取失败逐层添加查询上下文，保留底层原因而不依赖文本解析。
在索引查询边界用 errors.As 提取文档字段，决定向用户展示哪一层上下文。

## 复现
TAG=latest scripts/run-example.sh go L1-020-error-wrapping
