# E-005-isolation-lost-update —— 隔离级别冲突现象与锁修复

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-005 隔离级别冲突现象），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「并发冲突的检测与处理」（`E-011-deadline-cancel` /
`E-011-context-timeout` 的并发侧）主题的 db 轨落地：
REPEATABLE READ 快照读下「读-算-写」会静默丢失更新——最危险的错误是**不报错**。

## 现象

两个会话在 REPEATABLE READ 下都读到 100，各自 +10 / +5 提交，最终值 105
而不是 115——A 的更新被 B 覆盖，全程无任何报错。修复方式是改用
`SELECT ... FOR UPDATE`（当前读 + 行锁）：后到者等锁 2 秒拿到 `1205`
锁等待超时，归因为 contention（可重试），等持锁方提交后重试，得到 120。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-005-isolation-lost-update
# 或单独跑断言：
bash db/examples/E-005-isolation-lost-update/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：`final_value=105`（丢失更新）→ `lost_update=yes` →
`for_update_timeout err=1205 class=contention retryable=yes` →
`retry_final=120`（修复后无丢失）。

## 为什么这样处理

- 丢失更新是「静默错误」：不抛异常、不写错误日志，只有对账能发现——
  所以计数 / 余额类「读-算-写」必须从一开始就用 `FOR UPDATE` 或原子
  `UPDATE ... SET value = value + ?`。
- 1205 与 1213 同为 contention，但语义不同：1205 是等锁超时（锁还在别人手里，
  重试要等对方结束），1213 是死锁被裁决（对方已回滚，立即重试即可）。
- 锁等待超时先 `ROLLBACK` 再重试：失败的语句虽然没改数据，
  但事务里的读快照已经不可信。

## 反例

- 「隔离级别是 REPEATABLE READ 就不会丢数据」——可重复读防的是脏读 /
  不可重复读，不防丢失更新。
- 用「读出来在应用层算再写回」且不加锁——并发一上来必丢更新。
- 对 1205 无限重试——持锁方如果是长事务，重试只是把自己挂成新的等待者。

## 依赖服务

`mysql`

## 命名空间

`db_e_005_isolation_lost_update`
