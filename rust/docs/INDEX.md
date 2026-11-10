---
track: rust
guide: G4
dimensions: [D3, D8]
level: P1
status: draft
links: [知识点清单.md, 实践指南.md, 开发指南.md, 问题指南.md, 工具指南.md, FAQ.md, 错误处理指南.md, 排查手册.md, 工程参考.md]
examples: [E-001-error-taxonomy, E-007-error-aggregation, E-014-antipattern-catalog, L0-hello]
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-11
---

# Rust 轨道索引（INDEX）

> 本文只有一个主要承诺：**反查**。从任何一篇文档、一个 E 系用例或一个 lab 出发，
> 都能在这里找到它属于哪条学习线、下一步去哪。本文不含正文，全部条目外链到对应文件。

## 1. 指南层反查（7 篇既有指南 + 3 篇 M11 新增）

| 文件 | 类型 | 一句话职责 | 什么时候打开 |
|---|---|---|---|
| [知识点清单](知识点清单.md) | 清单 | L1/L2/L3 用例 ID 清单 + E 系反查表（§E） | 「练什么」 |
| [清单自检](清单自检.md) | 自检 | 探针式逐 KP 快速自测 | 怀疑某个 KP 没学会 |
| [实践指南](实践指南.md) | G1 | 知识点放进真实任务：何时用/不用会怎样 | 想把 KP 用起来 |
| [开发指南](开发指南.md) | G2 | 环境到提交的完整动线 | 从零开始动手 |
| [问题指南](问题指南.md) | G3 | 按问题域组织疑难：现象→假设→定位→修复 | 卡在一个具体故障（语言层） |
| [工具指南](工具指南.md) | G4 | 工具清单、调用、参数速查 | 查工具用法 |
| [FAQ](FAQ.md) | G5 | 高频短问答 | 10 秒内想要答案 |
| [错误处理指南](错误处理指南.md) | G1（M11 新增） | 错误处理操作动线：分类→表达→传播→报告 | 写错误处理代码时 |
| [排查手册](排查手册.md) | G3（M11 新增） | E 系 15 节：症状→命令→判据→修复 | 排查错误处理类故障 |
| [工程参考](工程参考.md) | G4（M11 新增） | 镜像/构建/依赖/环境变量/版本真本速查 | 查工程事实 |

## 2. E 系示范用例反查（15 例）

全部位于 `rust/examples/`，运行契约 `TAG=latest scripts/run-example.sh rust <ID>`；
一行速查版在 [知识点清单 §E](知识点清单.md)，逐例正文在各自 README。

| 用例 | 考点关键词 | 主关联文档 |
|---|---|---|
| [E-001-error-taxonomy](../examples/E-001-error-taxonomy/README.md) | 错误分类：Result vs panic | [排查手册](排查手册.md) §2.1 |
| [E-002-main-return-result](../examples/E-002-main-return-result/README.md) | main 返回 Result、退出码 1 | [排查手册](排查手册.md) §2.2 |
| [E-003-unwrap-expect-hygiene](../examples/E-003-unwrap-expect-hygiene/README.md) | unwrap/expect 治理、退出码 101 | [排查手册](排查手册.md) §2.3 |
| [E-004-from-vs-map-err](../examples/E-004-from-vs-map-err/README.md) | ? 即 From::from、map_err | [排查手册](排查手册.md) §2.4 |
| [E-005-box-dyn-error](../examples/E-005-box-dyn-error/README.md) | Box<dyn Error>、downcast | [排查手册](排查手册.md) §2.5 |
| [E-006-context-layering](../examples/E-006-context-layering/README.md) | 语境分层、source 链 | [排查手册](排查手册.md) §2.6 |
| [E-007-error-aggregation](../examples/E-007-error-aggregation/README.md) | 批量聚合 vs 短路 | [排查手册](排查手册.md) §2.7 |
| [E-008-retry-backoff](../examples/E-008-retry-backoff/README.md) | 重试分类、指数退避 | [排查手册](排查手册.md) §2.8 |
| [E-009-iterator-error-flow](../examples/E-009-iterator-error-flow/README.md) | 迭代器四种错误流 | [排查手册](排查手册.md) §2.9 |
| [E-010-fail-fast-validation](../examples/E-010-fail-fast-validation/README.md) | 整批校验、副作用隔离 | [排查手册](排查手册.md) §2.10 |
| [E-011-error-display-reporting](../examples/E-011-error-display-reporting/README.md) | 用户/排障双视图 | [排查手册](排查手册.md) §2.11 |
| [E-012-error-observability](../examples/E-012-error-observability/README.md) | stdout/stderr 分流、metrics | [排查手册](排查手册.md) §2.12 |
| [E-013-graceful-degradation](../examples/E-013-graceful-degradation/README.md) | 降级链、来源标签 | [排查手册](排查手册.md) §2.13 |
| [E-014-antipattern-catalog](../examples/E-014-antipattern-catalog/README.md) | 三大反模式对照 | [排查手册](排查手册.md) §2.14 |
| [E-015-thread-error-propagation](../examples/E-015-thread-error-propagation/README.md) | 线程错误传播、锁中毒 | [排查手册](排查手册.md) §2.15 |

## 3. 轨道 lab 反查（1 个）

| lab | 故障形态 | 入口 | 判读文档 |
|---|---|---|---|
| T-001-borrow-trait-conflict | 编译期拒绝：E0119 coherence 掩蔽 E0502 借用冲突，双缺陷 | `rust/labs/T-001-borrow-trait-conflict/run.sh` | [WALKTHROUGH.md](../labs/T-001-borrow-trait-conflict/WALKTHROUGH.md) |

lab 独立于 `examples/`（不进用例计数）；演练规范真本 [docs/72](../../docs/72-排障演练规范.md)。

## 4. 清单 E 段反查

[知识点清单 §E — 错误处理 / 工程与排查](知识点清单.md)：15 行索引表
（用例 ID / 考点 / 现象 / 排查命令实录 / 判据 / 关联文档 / 关联 lab），
是「从症状找用例」的最短入口；本文 §2 与它互为正反查。

## 5. 查不到时去哪查

- 轨道内：[FAQ](FAQ.md) → [问题指南](问题指南.md) → [排查手册](排查手册.md)；
- 仓库级：[docs/13-通用开发指南](../../docs/13-通用开发指南.md)（T0 动线）、
  [docs/ROADMAP.md](../../docs/ROADMAP.md) KI 段（已登记问题）、
  [docs/24-G3素材池](../../docs/24-G3素材池.md)（排查素材纪律）；
- 仍查不到：到仓库 issue 搜索关键词（现象原文），搜不到再提新 issue。
