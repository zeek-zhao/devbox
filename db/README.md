# db —— 数据库学习轨道（第 7 条）

五库（MySQL / PostgreSQL / MongoDB / Redis / SQLite）在 Docker 里跑，
**77 个用例**分四级，全部由一个跨五库的「带缓存的订单服务」毕业项目串起来。

## 为什么它和六门语言不一样

语言轨道的用例是 `docker run --rm` 一次性容器里跑 `run.sh`，stdout 逐行 diff。
数据库天生是**多容器 + 有状态 + 需要等待就绪**，硬套那套契约只会写出大量 sleep 和脆弱断言。
所以 db 轨道**自带 runner**，根 `scripts/run-example.sh` 一行不改：

```
db/scripts/run-example.sh db --all      # 跑全部 77 个
db/scripts/run-example.sh db L1-MY-01-create-and-types
```

`db/examples/<ID>/run.sh` 跑在**宿主**上，通过 `docker compose exec` 进入 `toolbox` 再连各库。
这样用例写的是「真查数据库」，而不是「sleep 后假装查到了」。

## 分级

| 级别 | 含义 | 例数 |
|---|---|---|
| L1 | 单库基础：这个库怎么用 | 40（五库 × 8） |
| L2 | 工程能力：怎么用对（慢查询/事务/备份/权限/迁移） | 15 |
| L3 | 专题：复制/分片/分区/分布式锁/缓存故障/TLS | 12 |
| L4 | 数据设计：建模/索引设计/一致性模式/多租户 | 10 |

L1 按库切（「这个库怎么用」天然属于单个库），L2 以上按跨库主题切——
「事务」「索引」「备份」放在一起对照五个库，比五个库各自讲一遍有价值得多。

## 快速开始

```bash
db/scripts/up.sh            # 起五库 + toolbox（首次会构建 toolbox）
db/scripts/wait-ready.sh    # 等全部就绪
db/scripts/run-example.sh db --all
db/scripts/down.sh          # 关掉
```

## 镜像

Docker Hub 直连在 215 上不通，默认走 `docker.m.daocloud.io` 镜像源。
要换源：`DB_IMAGE_PREFIX=... db/scripts/up.sh`。
