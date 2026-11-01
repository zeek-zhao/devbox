<!-- coverage: pending -->

# L1-MY-03-join-group · 多表连接与分组

## 考点
- `LEFT JOIN` 保留没有成员的团队，缺失端显示为 `NULL`。
- 区分 `COUNT(*)` 的连接行数与 `COUNT(member_key)` 的非空成员数。
- `HAVING` 过滤聚合结果，并以排序后的 `GROUP_CONCAT` 汇总业务键。

## 为什么这么写
数据中包含有两个成员、一个成员和零成员的团队，因此结果能实际体现连接补空与聚合过滤，而非只验证有匹配行的普通连接。

## 易错点
- 左连接无匹配时 `COUNT(*)` 仍为 1，成员数必须用非空列计数。
- `GROUP_CONCAT` 内单独指定排序，否则拼接顺序不保证。

## 依赖服务
`mysql`

## 命名空间
`db_l1_my_03_join_group`
