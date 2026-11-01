<!-- coverage: pending -->

# L2-07-backup-restore-drill · 备份恢复演练

## 考点

- 使用 `pg_dump` 导出专属源数据库，并用 `pg_restore` 恢复到另一个新建数据库。
- 恢复校验同时比较行数和按业务键排序计算的内容 checksum。
- 源库和恢复库分开，演练不覆盖原始数据。

## 为什么这么写

在 toolbox 的 `/tmp` 存储本例自定义格式备份，使用三个固定业务键和整数值；恢复后比较 `COUNT(*)` 与 `md5(string_agg(... ORDER BY ...))`，避免只验证 schema 或只数行。

## 易错点

- 不要把备份恢复到源库，否则无法证明备份包含可恢复的数据。
- `string_agg` 必须显式排序，避免 checksum 因聚合顺序不同而变化。
- 临时备份文件在退出时清理；源库、目标库均只使用本例命名空间。

## 依赖服务

`postgres`

## 命名空间

`db_l2_07_backup_restore_drill`，恢复库 `db_l2_07_backup_restore_drill_restore`
