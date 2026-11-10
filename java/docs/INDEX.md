---
track: java
guide: reference       # Diátaxis reference（轨道索引）；M11-DOC 新增文档类型，不在 docs/11 §1 的 G1..G5 五类之列
dimensions: [D8]
level: P1
status: draft
links: [知识点清单.md, 错误处理指南.md, 排查手册.md, 工程参考.md]
examples: [L0-hello, E-001-exception-taxonomy, E-015-antipattern-compare]
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-11
---

# Java 轨道索引（INDEX）

> 反查表：从「我要的东西」反查到具体文件。覆盖本轨 10 篇指南文档、
> 15 个 E 类示例、1 个 lab 与清单 E 段。全站索引归 `docs/INDEX.md`（本卡不改）。

## 1. 指南文档反查（10 篇）

| 文档 | 类型 | 回答的问题 |
|---|---|---|
| [知识点清单](知识点清单.md) | 清单 | 练什么：L0/L1/L2/L3/L4 用例 ID 清单 + E 段反查表 |
| [实践指南](实践指南.md) | G1 how-to | 什么时候用、不用会怎样、怎么验 |
| [开发指南](开发指南.md) | G2 how-to | 从零到能改：环境、目录、构建、提交动线 |
| [问题指南](问题指南.md) | G3 troubleshooting | 按问题域的疑难：现象 → 假设 → 定位 → 修复 |
| [工具指南](工具指南.md) | G4 reference | javac/java/jcmd/jstack 等工具速查与误用 |
| [FAQ](FAQ.md) | G5 reference | 高频短问答 |
| [清单自检](清单自检.md) | 探针 | 知识点清单的三条实跑探针 |
| [错误处理指南](错误处理指南.md) | how-to（M11-DOC 新增） | 要把错误处理写对：任务 → 动作 → E 例 → 验证命令 |
| [排查手册](排查手册.md) | troubleshooting（M11-DOC 新增） | 坏了怎么查：症状 → 命令 → 判据 → 修复（§2 逐节对应 E-001..E-015） |
| [工程参考](工程参考.md) | reference（M11-DOC 新增） | 镜像层/版本真本/命令/环境变量/计数口径查表 |

## 2. E 类示例反查（15 个，`java/examples/E-0xx-*`）

详细判读统一走 [排查手册](排查手册.md) §2 对应节；本表只做 ID → 考点反查。

| 用例 | 一句话考点 | 排查手册节 |
|---|---|---|
| [E-001-exception-taxonomy](../examples/E-001-exception-taxonomy/README.md) | 异常分类与策略映射 | §2.1 |
| [E-002-cause-chain-walk](../examples/E-002-cause-chain-walk/README.md) | cause 链多层包装与根因提取 | §2.2 |
| [E-003-catch-order](../examples/E-003-catch-order/README.md) | 多 catch 顺序与联合捕获 | §2.3 |
| [E-004-interrupt-handling](../examples/E-004-interrupt-handling/README.md) | 中断处理与协作式取消 | §2.4 |
| [E-005-uncaught-handler](../examples/E-005-uncaught-handler/README.md) | 线程未捕获异常的两条出口 | §2.5 |
| [E-006-suppressed-cleanup](../examples/E-006-suppressed-cleanup/README.md) | 清理失败不遮盖主异常 | §2.6 |
| [E-007-retry-backoff](../examples/E-007-retry-backoff/README.md) | 重试与指数退避 | §2.7 |
| [E-008-oom-taxonomy](../examples/E-008-oom-taxonomy/README.md) | JVM 致命错误分类 | §2.8 |
| [E-009-assert-contract](../examples/E-009-assert-contract/README.md) | 断言与契约分层 | §2.9 |
| [E-010-structured-logging](../examples/E-010-structured-logging/README.md) | 结构化错误日志 | §2.10 |
| [E-011-deadlock-diagnosis](../examples/E-011-deadlock-diagnosis/README.md) | 死锁检测与锁序修复 | §2.11 |
| [E-012-error-aggregation](../examples/E-012-error-aggregation/README.md) | 多任务错误聚合 | §2.12 |
| [E-013-exit-code-protocol](../examples/E-013-exit-code-protocol/README.md) | 失败退出码协议 | §2.13 |
| [E-014-graceful-degradation](../examples/E-014-graceful-degradation/README.md) | 优雅降级 | §2.14 |
| [E-015-antipattern-compare](../examples/E-015-antipattern-compare/README.md) | 反模式对照（吞错 vs 类型分流） | §2.15 |

清单侧反查表见 [知识点清单](知识点清单.md) `## E` 段（逐行含排查命令与判据）。

## 3. lab 反查（1 个）

| lab | 场景 | 判读文档 |
|---|---|---|
| [T-001-deadlock-oom](../labs/T-001-deadlock-oom/WALKTHROUGH.md) | 死锁互等闭环 + 小堆 OOM：jcmd/jstack/top/javac 交叉验证 | `java/labs/T-001-deadlock-oom/WALKTHROUGH.md` |

## 4. 「我要查 X」反查示例

- 我要练某个语法点 → [知识点清单](知识点清单.md) L1/L2/L3/L4 段按 ID 查。
- 我要把错误处理写对 → [错误处理指南](错误处理指南.md) §2 任务路由表。
- 我手上有个故障 → [排查手册](排查手册.md)按症状找节；并发/JVM 类走 §3 路由。
- 我要查镜像/版本/环境变量 → [工程参考](工程参考.md) §2、§4。
- 我要跑某个用例 → `TAG=latest scripts/run-example.sh java <ID>`（契约见
  [工程参考](工程参考.md) §3）。
- 我要做一个排障演练 → [T-001 WALKTHROUGH](../labs/T-001-deadlock-oom/WALKTHROUGH.md)，
  规范见 [docs/72](../../docs/72-排障演练规范.md)。
- 我有小疑问 → [FAQ](FAQ.md)；查不到的入口在各篇「相关」节与
  [docs/ROADMAP](../../docs/ROADMAP.md) KI 段。
