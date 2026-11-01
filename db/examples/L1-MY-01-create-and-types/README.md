
# L1-MY-01-create-and-types · 建表与数据类型

## 考点
- 对比 `CHAR`/`VARCHAR`、`ENUM`/`VARCHAR` 的元数据定义。
- 检查 `SMALLINT UNSIGNED` 与 `DECIMAL(10,2)` 精度声明。
- 从 `information_schema.columns` 验证字符集及四张表的列定义。

## 为什么这么写
查询系统元数据而不是重复输出建表语句，能验证服务器实际接受并保存的类型定义。结果明确选取表名、列名、类型和字符集，并按表与列序排列。

## 易错点
- 数值列没有字符集，输出用 `-` 归一化，避免空字段不易辨认。
- `CHAR`/`VARCHAR` 语义相似但元数据定义不同；只看插入后的值无法覆盖此考点。

## 依赖服务
`mysql`

## 命名空间
`db_l1_my_01_create_and_types`
