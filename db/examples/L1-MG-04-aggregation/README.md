<!-- coverage: pending -->

# L1-MG-04-aggregation · 聚合管道

## 考点
- `$match` 与 `$unwind` 先筛选再展开订单明细，`$lookup` 关联客户。
- `$group` 聚合每种 SKU 的件数与订单数，`$sort` 和 `$project` 固定输出顺序及形状。
- `$facet` 在同一输入上计算订单数和不同客户数。

## 为什么这么写
订单和客户分别使用可读业务键，聚合结果只显示 SKU 和统计值。`$addToSet` 再 `$size` 统计不同订单，不会把同一订单中同 SKU 的多条明细重复计为多个订单。

## 易错点
- `$unwind` 会将每个明细变成独立管道文档；先对订单计数会得到不同含义。
- `$lookup` 返回数组，后续按客户字段分组前需要再次 `$unwind`。
- `$group` 不保证顺序，必须显式 `$sort`。

## 依赖服务
`mongodb`

## 命名空间
`db_l1_mg_04_aggregation`
