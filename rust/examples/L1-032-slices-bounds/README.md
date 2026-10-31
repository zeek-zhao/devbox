# L1-032-slices-bounds

<!-- coverage: pending -->

## 考点
对应 KP-RS-L1-32：用切片借用连续元素，并通过 `get` 检查索引边界。
看到合法切片与索引可读、越界查询返回 `None` 且长度不变，说明掌握了边界处理。

## 易错点
未经检查就用索引访问外部输入可能触发 panic。
先用 `get` 检查边界，再决定返回错误或访问元素。

## 延伸
将固定数组换成 `Vec<T>`，用相同的切片借用方式读取区间。
把 `Option<&T>` 转为调用方可处理的查询结果。

## 复现
TAG=latest scripts/run-example.sh rust L1-032-slices-bounds
