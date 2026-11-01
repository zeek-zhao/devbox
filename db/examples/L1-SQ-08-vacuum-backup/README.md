
# L1-SQ-08-vacuum-backup · VACUUM INTO 备份

## 考点
- 设置并读取固定的 `page_size`，通过删除行制造可回收空间后执行 `VACUUM`。
- 使用 `VACUUM INTO` 生成另一数据库文件，并对备份运行 `integrity_check`。
- 在备份库中检查实际行数，另验证文件非空。

## 为什么这么写
只判断文件大小会把损坏或空数据库误判为可用备份；恢复检查同时验证完整性和业务行数。

## 易错点
- `VACUUM INTO` 的目标不能已存在，所以每次运行前清理目标文件。
- SQLite 备份文件位于 toolbox 的 `/tmp`，验证必须对备份文件本身执行，而非只检查源库。

## 依赖服务
`toolbox`

## 命名空间
`/tmp/l1-sq-08-vacuum-backup.db` 与 `/tmp/l1-sq-08-vacuum-backup-copy.db`
