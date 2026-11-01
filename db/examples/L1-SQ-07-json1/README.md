<!-- coverage: pending -->

# L1-SQ-07-json1 · json1 扩展

## 考点
- 使用 `json_each` 将对象展开为有序键值和 JSON 类型。
- 用 `json_extract`/`json_set` 读取并变更 JSON 数值。
- 对比 `->` 返回 JSON 表示与 `->>` 返回 SQL 标量。

## 为什么这么写
键名排序后输出 `json_each` 展开的真实行；同一文档同时运行路径函数与运算符，便于观察返回类型差异。

## 易错点
- `json_each` 的键值行顺序不应依赖对象存储顺序，必须显式 `ORDER BY key`。
- `->` 的字符串结果保留 JSON 引号，`->>` 返回不带引号的 SQL 文本。

## 依赖服务
`toolbox`

## 命名空间
`/tmp/l1-sq-07-json1.db`
