# E-013-backup-corrupt-detect —— 备份完整性：截断检测、恢复失败归因与完好副本兜底

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-013 备份损坏的检测与恢复验收），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「失败要被发现」（`E-013-error-observability`）主题的 db 轨落地：
备份是一份「延迟执行的代码」——损坏不会在备份时暴露，而在恢复那一刻爆炸。
让损坏**在恢复前被发现**、恢复失败有明确归因、恢复成功有指纹验收，三件缺一不可。

## 现象

mysqldump 产物被截断 40% 后：尾部 `Dump completed` 标记消失（恢复前就能发现）；
强行恢复则在断句处报 `1064`（语法错误）——这个 1064 的真实含义不是「SQL 写错了」，
而是「备份不完整」。换完好副本恢复，`CHECKSUM TABLE` 与源表一致才算恢复成功。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-013-backup-corrupt-detect
# 或单独跑断言：
bash db/examples/E-013-backup-corrupt-detect/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：`tail_marker good=yes bad=no` →
`corrupt_restore stmts_done=2 err=1064 detected=yes`（坏副本走到第 3 句断掉）→
`good_restore rows=3 checksum_match=yes`。

## 为什么这样处理

- 尾部标记是最便宜的完整性检查：mysqldump 每次收尾都写 `Dump completed`，
  缺了它 = 文件不完整，不用真恢复就能拒收。
- 1064 在恢复语境下要重新归因：同一句法错误码，平时是「SQL 写错」，
  恢复时报大概率是「备份被截断/篡改」——归因要带着语境做。
- 恢复验收用 `CHECKSUM TABLE` 对比源表：行数一致也可能内容不同，
  校验和是字节级指纹；验收不过的恢复等于没恢复。
- 「先验坏副本再验好副本」证明检测逻辑真的能拦住坏备份——
  只测好副本的恢复流程，检测代码永远是死代码。

## 反例

- 备份定时跑、从不恢复演练——损坏第一次被发现是在最需要它的事故夜。
- 恢复脚本 `mysql < dump.sql` 不看退出码——截断的备份恢复出半套数据还不报错。
- 只对文件做 md5 就当完整性验证——校验的是「没变」，不是「完整」。

## 依赖服务

`mysql`

## 命名空间

`db_e_013_backup_corrupt_detect`
