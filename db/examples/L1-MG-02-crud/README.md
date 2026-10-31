<!-- coverage: pending -->

# L1-MG-02-crud · CRUD 与 upsert

## 考点
- `insert_many` 初始化两条带业务键的文档，更新前后数量可对照。
- `$set` 与 `$inc` 修改已有文档，`replace_one` 展示整文档替换，upsert 创建缺少的键。
- `delete_many` 按业务键删除两条记录，最后核对剩余文档。

## 为什么这么写
每条文档都指定字符串 `_id`，排序后输出字段而不是 MongoDB 自动生成的 ObjectId。操作结果用文档数和最终字段值判定，避免输出结果对象中不稳定的信息。

## 易错点
- replace 操作会替换整条文档，遗漏字段不会被保留。
- 没有 upsert 选项时，匹配不到 `p3` 不会创建文档。
- 查询必须按 `_id` 排序；集合默认顺序不构成保证。

## 依赖服务
`mongodb`

## 命名空间
`db_l1_mg_02_crud`
