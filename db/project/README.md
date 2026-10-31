# 毕业项目：带缓存的订单服务

把 77 个用例串起来的那一个项目。**跨五库**：

| 库 | 承担什么 |
|---|---|
| MySQL | 订单主数据（订单头 + 明细 + 状态机） |
| Redis | 缓存 + 分布式锁 + 排行榜 |
| PostgreSQL | 报表聚合（物化视图 + 窗口函数） |
| MongoDB | 行为日志（半结构化、按天归档） |
| SQLite | 本地配置与离线快照 |

## 为什么是它

单库项目只能证明「会用某个库」，证明不了「知道什么时候该用哪个库」——
后者才是数据库能力里最值钱的部分。

## 验收

```bash
bash db/scripts/run-example.sh db            # 用例全绿
bash scripts/coverage-check.sh db            # 覆盖表与 project/ 对得上
bash db/project/run.sh                       # 项目自身的端到端
```

## 状态

骨架待实现（DB-06）。
