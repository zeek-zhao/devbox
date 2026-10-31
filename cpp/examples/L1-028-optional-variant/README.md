# L1-028-optional-variant


## 考点
对应 KP-L1-28：`optional` 明确输出缺失状态，只有有值时才解引用。
`variant` 互斥保存整数或字符串；`get_if` 与 `holds_alternative` 显示当前分支。

## 易错点
未检查就解引用空 `optional` 会造成错误访问；先检查 `has_value()` 或条件状态。
直接假定 `variant` 当前类型会令访问不安全；先检查分支，再读取对应值。

## 延伸
可用 `optional` 表示查询未命中，并用 `variant` 设计成功值与多种错误状态。
进一步练习 `std::visit`，为每个互斥分支提供明确处理。

## 复现
TAG=latest scripts/run-example.sh cpp L1-028-optional-variant
