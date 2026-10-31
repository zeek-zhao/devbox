
# L4-10-report-aggregation · 报表聚合

## 考点
- MySQL 触发器维护预聚合汇总表，并与对源表实时 `SUM` 的结果比较。
- PostgreSQL 刷新物化视图后同样与实时聚合比较。
- 两个数据库分别输出 `equal=1`，这是本用例的硬判据。

## 为什么这么写
MySQL 汇总表演示写时同步维护；PostgreSQL 物化视图演示批量刷新后供读端复用。金额使用 DECIMAL/NUMERIC 并按两位精度求和，避免浮点输出波动。

## 易错点
- 物化视图不会随源表写入自动更新，必须显式 `REFRESH` 后再比较。
- 汇总表触发器若只维护 INSERT，真实系统还需覆盖 UPDATE/DELETE；此用例限定在只追加销售数据的场景。

## 依赖服务
`mysql`、`postgres`

## 命名空间
MySQL `db_l4_10_report_aggregation`；PostgreSQL `l4_10_report_aggregation`
