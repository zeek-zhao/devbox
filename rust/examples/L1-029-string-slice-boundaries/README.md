# L1-029-string-slice-boundaries


## 考点
对应 KP-RS-L1-29：字符串切片索引是字节位置，端点必须位于 UTF-8 边界。
看到 `1..4` 得到完整的“中”、边界为 `[0, 1, 4, 5]`、三种非法范围均返回 `None`，说明能够安全选取片段。

## 易错点
按字符序号计算字节位置后直接索引会 panic，因为一个非 ASCII 字符可能跨多个字节。
不确定边界时使用 `get` 并检查 `Option`；本例安全处理编码内部端点及越界，不执行会 panic 的直接索引。

## 延伸
在毕业项目中为高亮区间保存字节偏移，展示前用 `get` 验证区间。
使用 `char_indices` 从标量遍历取得真实字节位置，再构建合法文档片段。

## 复现
TAG=latest scripts/run-example.sh rust L1-029-string-slice-boundaries
