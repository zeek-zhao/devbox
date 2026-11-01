
# L1-PG-01-types-jsonb · 建表与 jsonb/array

## 考点

- `json` 与 `jsonb` 是不同存储类型；`jsonb` 路径提取能直接访问嵌套字段。
- PostgreSQL 数组可用 `unnest` 展开，结果仍需显式排序。
- `int4range` 保存范围边界，`[1,5)` 表示含下界、不含上界。

## 为什么这么写

同一行同时存 `json`、`jsonb`、`text[]` 和 `int4range`，输出路径字段、数组元素及范围文本，确保查询确实使用这些类型；固定单行输入避免生成不确定值。

## 易错点

- `json` 与 `jsonb` 并非可互换的类型别名。
- `unnest` 的输出顺序不保证，因此数组展开查询显式 `ORDER BY`。
- 范围边界符号有含义，不能把 `[1,5)` 当成两端都包含。

## 依赖服务

`postgres`

## 命名空间

`db_l1_pg_01_types_jsonb`
