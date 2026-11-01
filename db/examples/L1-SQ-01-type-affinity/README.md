
# L1-SQ-01-type-affinity · 类型亲和性

## 考点
- 对同一组文本/整数输入观察 INTEGER、TEXT、REAL、NUMERIC、BLOB 五种亲和性结果。
- 比较无声明类型列对文本和整数的动态存储类型。
- 验证 `STRICT` 表及 BLOB 字面量的实际 `typeof`。

## 为什么这么写
同时插入文本 `'123'` 和整数 `123`，再读取 SQLite 的 `typeof()`，让亲和性转换体现在实际存储结果中，而不依赖声明推测。

## 易错点
- `TEXT` 亲和性会把整数转换成文本，`BLOB`/无类型列则保留输入存储类型。
- SQLite `STRICT` 表仍允许可无损转换的文本数值写入整数列。

## 依赖服务
`toolbox`

## 命名空间
`/tmp/l1-sq-01-type-affinity.db`
