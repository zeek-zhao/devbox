# E-004-rollback-savepoint —— 事务回滚与保存点（含 PG 事务中止态对照）

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-004 事务回滚与保存点），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「失败后的清理与回滚」（`E-007-goto-cleanup` / `E-007-defer-cleanup`）
主题的 db 轨落地：保存点是事务内的「检查点」，错误后可部分回滚；
MySQL 与 PostgreSQL 对「错误之后的事务状态」语义不同，处理代码必须跟着变。

## 现象

批量写入中一条违反唯一约束：MySQL 里事务仍然可用，`ROLLBACK TO SAVEPOINT`
只丢弃出错后的写入，前面的行保留；PostgreSQL 里同一场景事务直接进入
aborted 状态，后续任何语句都报 `25P02`（current transaction is aborted），
必须整体 `ROLLBACK`——除非错误前打过 `SAVEPOINT` 并 `ROLLBACK TO` 它。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-004-rollback-savepoint
# 或单独跑断言：
bash db/examples/E-004-rollback-savepoint/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：MySQL 段 `violation err=1062` → `rows_after_rollback_to=2`
→ 修正后 `rows_final=3`；PG 段 `23505` → 后续语句 `25P02 aborted_txn` →
无保存点 `rows_committed=0` → 有保存点 `rows_committed=2`。

## 为什么这样处理

- MySQL 的错误不失效事务，保存点是「免费的撤销点」；PG 的错误作废整个事务，
  保存点是**唯一**的部分撤销手段——同一个「逐条容错」需求在两家的写法完全不同。
- `ROLLBACK TO sp` 之后事务还在，可以修正数据继续提交；整体 `ROLLBACK`
  之后一切归零。两条路径的选择取决于「错误可不可以就地修正」。
- PG 的 25P02 不是根因，是被中止事务的**次生错误**——排障时先找日志里
  第一条 23505，而不是最后一条 25P02。

## 反例

- 在 PG 里捕获 23505 后继续跑后面的语句——全部变成 25P02，真正的业务错误
  被次生错误淹没。
- MySQL 里以为「报错 = 整个事务回滚」而不打保存点——前面的行还在事务里，
  等到 COMMIT 才发现坏数据一起进去了。
- 保存点命名随手写（sp1/sp2/…）不复用——出错时不知道该回滚到哪个检查点。

## 依赖服务

`mysql`、`postgres`

## 命名空间

`db_e_004_rollback_savepoint`（MySQL）/ `e004`（PostgreSQL schema）
