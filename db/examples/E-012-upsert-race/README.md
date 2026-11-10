# E-012-upsert-race —— 唯一键竞态：INSERT 撞车 1062 与 upsert 收口

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-012 唯一键竞态与 upsert 收口），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「可重试错误的分类与重试预算」（`E-010-retry-backoff`）主题的
db 轨落地：唯一键竞态是少数「重试有意义」的 1062——与 E-002 的「约束违反不可重试」
对照：那次重试的是**同一条数据**，这里重试的是**换一种动作**（get-or-create / upsert）。

## 现象

两个会话并发插同一个唯一键：后者并不立刻报错，而是**阻塞在前者的未提交插入上**；
前者提交，阻塞者被放行后拿到 1062——竞态输家的报错时机取决于赢家何时提交。
赢家若回滚，同一个「输家」反而插入成功：1062 与否不由自己决定。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-012-upsert-race
# 或单独跑断言：
bash db/examples/E-012-upsert-race/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：`race_commit err=1062 action=adopt_existing` →
`adopted sku=widget-b qty=1`（输家改采用既有行）→ 竞态翻转
`race_rollback loser_ok=yes` → 惯用收口 `upsert_concurrent qty=110
lost_update=no`（两个并发 upsert 各 +5，无一丢失）。

## 为什么这样处理

- 捕获 1062 后先 `ROLLBACK`：报错的 INSERT 之前可能还有同事务的写入，
  直接继续跑会把半套状态带进下一步。
- get-or-create 的正确姿势是「撞 1062 → 回滚 → 读既有行」：读侧拿到的
  一定是赢家的已提交数据，不需要自己再判断谁赢了。
- 计数类写入用 `INSERT ... ON DUPLICATE KEY UPDATE qty = qty + 5`：
  自增在服务端原子完成，两个会话并发也不会丢更新；换成
  「读 qty → 写 qty+5」必然丢一次。
- 竞态 1062 重试（或改用 upsert）是有意义的：撞不撞取决于调度，不取决于数据本身
  ——这与 E-002「同一条脏数据重试一万次还是 1062」正是两种世界。

## 反例

- 把竞态 1062 当数据 bug 告警——它通常说明功能健康（真的有人在并发）。
- 捕获 1062 后不回滚直接 SELECT——读到的还是自己事务里的旧快照。
- 用「先 SELECT 有没有 → 再 INSERT」消竞态——检查与插入之间窗口仍在，
  除非把检查放进同一把锁里，否则只是把概率调小。

## 依赖服务

`mysql`

## 命名空间

`db_e_012_upsert_race`
