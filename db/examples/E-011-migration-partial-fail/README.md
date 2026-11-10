# E-011-migration-partial-fail —— 迁移中途失败：DML 回滚、DDL 残留与幂等重跑

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-011 迁移中途失败的部分应用处理），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「失败后的清理与回滚」（`E-007-goto-cleanup`）主题的 db 轨落地：
MySQL 的 DDL 每条自带原子提交、**回不去了**——迁移脚本中途失败必然留下
「部分应用」状态，处理套路是：DML 放事务里回滚、DDL 残留靠探测、重跑靠幂等。

## 现象

v2 迁移三步：加列（DDL，自动提交）→ 建索引写错列名（1072）→ 回填（还没轮到）。
失败后：新加的列**留在库里**（DDL 回不去），索引没建、回填没跑（`backfill_committed=0`）
——迁移卡在半套状态；直接重跑会在加列那步撞 1060（列已存在）。
注意一个更隐蔽的坑：MySQL 的 DDL 执行前后都有**隐式提交**，若把回填放在
失败的 DDL 之前，回填会被 DDL 的隐式提交抢先落库，rollback 根本救不回。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-011-migration-partial-fail
# 或单独跑断言：
bash db/examples/E-011-migration-partial-fail/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：`migration_failed err=1072 rollback_done=yes` →
`partial_applied last_login_column=yes`（DDL 残留）→ `backfill_committed=0`
（后续步骤没跑）→ 幂等重跑 `rerun backfill_committed=2`、`version_recorded=1` →
不带防护的重复迁移 `duplicate_column err=1060 handled=idempotent`。

## 为什么这样处理

- 失败后的第一动作是 `ROLLBACK` 当前事务，把失败事务干净地结束掉；
  残留的 DDL 靠 information_schema 探测——DDL 回不去，这是 MySQL 的硬约束。
- 别把 DML 回填押在「跟在 DDL 后面还能整体回滚」上：DDL 前后都有隐式提交，
  排在前面的回填会被抢跑落库。要保回滚语义，回填自成事务、放在 DDL 之后。
- 重跑必须幂等：每步先探测（列存在吗 / 索引在吗）再执行；1060/1050/1061
  （列/表/键已存在）捕获后按「已应用」处理，不是失败。
- 版本记录（schema_migrations）在**全部步骤成功之后**才写：写在开头，
  中途失败后重跑会被版本号骗过。

## 反例

- 把整个迁移包进一个大事务——DDL 会隐式提交，事务边界是假的，半套照样发生。
- 捕获 1060 就告警人工介入——已应用不是故障，告警把值班变成狼来了。
- 失败后直接重跑原始脚本——第一步就撞 1062/1060，错误掩盖了真正的失败步骤。

## 依赖服务

`mysql`

## 命名空间

`db_e_011_migration_partial_fail`
