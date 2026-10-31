<!-- coverage: pending -->

# L1-MG-07-dump-restore · 备份恢复

## 考点
- 对指定集合应用查询条件，按业务键排序后导出 JSON 行文件。
- 将 JSON 行文件导入独立目标库，校验恢复后的文档数、集合名和字段值。

## 为什么这么写
toolbox 未安装 `mongodump` / `mongorestore`，且官方数据库工具包不在 Ubuntu 源中；本例使用 pymongo 与 BSON JSON 编解码演示同一条导出、回灌和核验流程。临时文件使用 Python 临时文件，运行后自动清理。

## 易错点
- `json_util` 用于保留 BSON 特殊类型；普通 JSON 编码可能丢失类型信息。
- 导出过滤条件和恢复文档数必须一致；不能只打印预先写死的数量。
- 源库和恢复库分开，防止导入过程污染源数据。

## 依赖服务
`mongodb`

## 命名空间
`db_l1_mg_07_dump_restore`、`db_l1_mg_07_dump_restore_restored`
