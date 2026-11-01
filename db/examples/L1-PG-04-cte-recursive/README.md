<!-- coverage: pending -->

# L1-PG-04-cte-recursive · CTE 与递归

## 考点

- `WITH RECURSIVE` 从根节点逐层遍历组织树。
- 递归项用父子关系连接上一层，并拼接完整层级路径。
- `MATERIALIZED` 明确要求中间 CTE 物化。

## 为什么这么写

树数据只含一个根和两层子节点，路径和深度直接体现递归结果；将递归结果交给显式 `MATERIALIZED` 的 CTE，再按路径排序展示。

## 易错点

- 根节点要单独作为递归锚点，否则遍历不会开始。
- 递归连接方向写反会向上遍历或漏掉子节点。
- `MATERIALIZED` 是执行提示，不负责替代最终结果的排序。

## 依赖服务

`postgres`

## 命名空间

`db_l1_pg_04_cte_recursive`
