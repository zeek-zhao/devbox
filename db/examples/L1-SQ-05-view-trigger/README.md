<!-- coverage: pending -->

# L1-SQ-05-view-trigger · 视图与触发器

## 考点
- 通过 `INSTEAD OF INSERT` 触发器向视图写入，并同步写入审计表。
- 输出审计行数与基础表结果，确认触发器实际执行。
- 用递归 CTE 按层级生成有序路径。

## 为什么这么写
SQLite 普通视图不可直接插入，视图触发器把写入路由到基础表；审计表是触发器副作用的直接判据。

## 易错点
- SQLite 的 `INSTEAD OF` 触发器必须绑定到视图。
- 多行插入会对每个新行触发一次，审计记录数应等于写入行数。

## 依赖服务
`toolbox`

## 命名空间
`/tmp/l1-sq-05-view-trigger.db`
