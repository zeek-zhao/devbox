
# L1-MY-07-import-export · 导入导出

## 考点
- 用 `mysqldump --no-data` 和 `--no-create-info` 分离导出结构与数据。
- 统计数据 dump 中逐行 `INSERT` 语句数，并将两份文件导入新库。
- 比较导出行数与回灌后的真实 `COUNT(*)`。

## 为什么这么写
dump 文件存放在 toolbox 的 `/tmp`，避开 MySQL 服务端文件权限和 `secure_file_priv` 限制；恢复到独立库后直接验证数据可用。

## 易错点
- 不用 `SELECT ... INTO OUTFILE`：文件落在服务端容器，宿主无法直接读取。
- `--skip-extended-insert` 保证每行数据对应一条 `INSERT`，行数可稳定统计；导入使用目标库，不污染源库。

## 依赖服务
`mysql`

## 命名空间
源库 `db_l1_my_07_import_export`；恢复库 `db_l1_my_07_import_export_restore`
