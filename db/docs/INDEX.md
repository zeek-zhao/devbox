---
track: db
guide: reference       # Diátaxis reference（轨道索引）；M11-DOC 新增文档类型，不在 docs/11 §1 的 G1..G5 五类之列
dimensions: [D8]
level: P1
status: draft
links: [知识点清单.md, 排查手册.md]
examples: [L1-MY-01-create-and-types, E-001-conn-fail-retry, E-015-antipattern-swallow]
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-11
---

# db 轨道索引（INDEX）

> 反查表：从「我要的东西」反查到具体文件。反查范围按本轨**实际存在**的文件写：
> 指南层现有 3 篇 + 本卡新增 1 篇排查手册；`开发指南.md`（G2）/ `工具指南.md`
> （G4）/ `FAQ.md`（G5）为卡面「明确不做」项（已裁定，见 #322 明确不做节：
> 「不写 db 的 G2/G4/G5 三格」），此处如实登记、不留空指针。
> 全站索引归 `docs/INDEX.md`（本卡不改）。

## 1. 指南文档反查（按实际存在文件）

| 文档 | 类型 | 回答的问题 |
|---|---|---|
| [知识点清单](知识点清单.md) | 清单 | 练什么：L1–L4 用例 ID 契约 + E 段反查表 |
| [实践指南](实践指南.md) | G1 how-to | 什么时候用、不用会怎样、怎么验 |
| [问题指南](问题指南.md) | G3 troubleshooting | 按问题域的疑难：现象 → 假设 → 定位 → 修复 |
| [排查手册](排查手册.md) | troubleshooting（M11-DOC 新增） | 坏了怎么查：症状 → 命令 → 判据 → 修复（§2 逐节对应 E-001..E-015） |
| ~~开发指南.md（G2）~~ | 明确不做（已裁定） | 构建运行事实由 `db/README.md` 与 [docs/13-通用开发指南](../../docs/13-通用开发指南.md) 承接 |
| ~~工具指南.md（G4）~~ | 明确不做（已裁定） | EXPLAIN 等工具内容在 [问题指南](问题指南.md) 与 lab WALKTHROUGH 内承接 |
| ~~FAQ.md（G5）~~ | 明确不做（已裁定） | 高频短答暂由 [问题指南](问题指南.md) 承接 |

## 2. E 类示例反查（15 个，`db/examples/E-0xx-*`）

详细判读统一走 [排查手册](排查手册.md) §2 对应节；本表只做 ID → 考点反查。

| 用例 | 一句话考点 | 排查手册节 |
|---|---|---|
| [E-001-conn-fail-retry](../examples/E-001-conn-fail-retry/README.md) | 连接失败分类与重试预算 | §2.1 |
| [E-002-constraint-catch](../examples/E-002-constraint-catch/README.md) | 约束违反逐个归因 | §2.2 |
| [E-003-deadlock-retry](../examples/E-003-deadlock-retry/README.md) | 死锁受害者归因与重试 | §2.3 |
| [E-004-rollback-savepoint](../examples/E-004-rollback-savepoint/README.md) | 保存点与 PG 事务中止态 | §2.4 |
| [E-005-isolation-lost-update](../examples/E-005-isolation-lost-update/README.md) | 丢失更新与 FOR UPDATE 修复 | §2.5 |
| [E-006-conn-limit-exhaust](../examples/E-006-conn-limit-exhaust/README.md) | 连接配额耗尽的让路动作 | §2.6 |
| [E-007-query-timeout](../examples/E-007-query-timeout/README.md) | 语句超时与锁等待超时 | §2.7 |
| [E-008-permission-denied](../examples/E-008-permission-denied/README.md) | 权限拒绝的归因与修复路径 | §2.8 |
| [E-009-charset-mojibake](../examples/E-009-charset-mojibake/README.md) | 字符集错配与 HEX 校验 | §2.9 |
| [E-010-null-semantics](../examples/E-010-null-semantics/README.md) | NULL 语义陷阱 | §2.10 |
| [E-011-migration-partial-fail](../examples/E-011-migration-partial-fail/README.md) | 迁移半套状态与幂等重跑 | §2.11 |
| [E-012-upsert-race](../examples/E-012-upsert-race/README.md) | 唯一键竞态与 upsert 收口 | §2.12 |
| [E-013-backup-corrupt-detect](../examples/E-013-backup-corrupt-detect/README.md) | 备份完整性检测 | §2.13 |
| [E-014-fk-cascade-trap](../examples/E-014-fk-cascade-trap/README.md) | 外键级联的静默丢失 | §2.14 |
| [E-015-antipattern-swallow](../examples/E-015-antipattern-swallow/README.md) | autocommit + 吞错对照 | §2.15 |

清单侧反查表见 [知识点清单](知识点清单.md) `## E` 段（逐行含排查命令与判据）。

## 3. lab 反查（1 个）

| lab | 场景 | 判读文档 |
|---|---|---|
| [T-001-slow-query-repeatable-read](../labs/T-001-slow-query-repeatable-read/WALKTHROUGH.md) | MySQL 慢查询定位与可重复读快照读（EXPLAIN / Handler 计数器 / 双会话时序） | `db/labs/T-001-slow-query-repeatable-read/WALKTHROUGH.md` |

## 4. 「我要查 X」反查示例

- 我要练某个库/主题 → [知识点清单](知识点清单.md) L1–L4 段按 ID 查。
- 我手上有个故障 → [排查手册](排查手册.md)按症状找节；慢查询/隔离级别走 §3 路由。
- 我要起五库栈 / 跑用例 → `db/README.md`（`up.sh` + `wait-ready.sh`；
  `bash db/scripts/run-example.sh db <ID>`）。
- 我要做一个排障演练 → [T-001 WALKTHROUGH](../labs/T-001-slow-query-repeatable-read/WALKTHROUGH.md)，
  规范见 [docs/72](../../docs/72-排障演练规范.md)。
- 我要查跨语言的通用开发流程 → [docs/13-通用开发指南](../../docs/13-通用开发指南.md)
  （db 轨的 G2 明确不做，由 T0 真本承接）。
- 按问题域的疑难 → [问题指南](问题指南.md)。
