# E-007-query-timeout —— 慢查询超时：语句超时与锁等待超时

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-007 语句超时与锁等待超时），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「超时与截止时间」（`E-011-deadline-cancel`）主题的 db 轨落地：
两类超时错误码不同、后果不同——`3024`（MAX_EXECUTION_TIME）杀掉的是整条只读语句，
`1205`（innodb_lock_wait_timeout）只回滚当前语句、**事务还开着**。

## 现象

读放大的聚合（4 表笛卡尔积）超过 `MAX_EXECUTION_TIME(1000)` 后报 `3024`；
另一会话持有行锁不提交，等待方在 `innodb_lock_wait_timeout=2` 后报 `1205`。
1205 之后连接没有断、事务还活着——以为「超时=回滚完事」直接继续跑，
后面的语句会带着没打算提交的旧事务上下文走。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-007-query-timeout
# 或单独跑断言：
bash db/examples/E-007-query-timeout/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：`stmt_timeout err=3024`、`lock_timeout err=1205`、
1205 后 `victim_txn_alive id2=100`（事务仍可查询）、持锁方提交后
`retry ok id=1 bal=100 / id=2 bal=100`（重试的 UPDATE 与持有方的 UPDATE 叠加，
净效果为零——这正是「重试的是整笔业务」的可验证结果）。

## 为什么这样处理

- 3024 的处理动作是 shrink（改写查询 / 加索引 / 限行数），不是重试同一句话——
  同一句话超时一次，再跑一遍大概率还超时。
- 1205 的处理动作是：等持锁方结束 → 自己 `ROLLBACK` 结束当前事务 → 再重试；
  「先回滚再重试」与死锁（E-003）同理，但 1205 不回滚事务也能继续跑，
  这正是最危险的地方。
- 超时参数打到 **session 级**（`SET SESSION innodb_lock_wait_timeout` /
  提示 `MAX_EXECUTION_TIME`），不动全局配置：演示故障不许改共享栈的默认行为。

## 反例

- 捕获 1205 后不回滚直接开新事务——旧事务上下文还挂着，提交边界全乱。
- 对 3024 无脑重试同一查询——超时是确定性结果，重试只是再等一次超时。
- 把 `innodb_lock_wait_timeout` 调大来「修」锁等待——环根在持锁方不提交，
  等得再久也只是把故障延迟。

## 依赖服务

`mysql`

## 命名空间

`db_e_007_query_timeout`
