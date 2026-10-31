
# L1-SQ-06-attach · 附加数据库

## 考点
- 用 `ATTACH` 将独立档案库挂载为 `archive`。
- 显式限定 `main`/`archive` 表名进行跨库连接、分组和计数。
- 以排序结果检查两个数据库之间的关联。

## 为什么这么写
主库和附加库使用不同文件，JOIN 必须跨数据库边界完成；独立文件也让重复运行清理范围明确。

## 易错点
- 附加数据库中的表要用 `archive.table` 标识，不能误读为 `main` 中的同名表。
- 先删除归档文件再 ATTACH，否则重复执行会叠加旧数据。

## 依赖服务
`toolbox`

## 命名空间
`/tmp/l1-sq-06-attach.db` 与 `/tmp/l1-sq-06-attach-archive.db`
