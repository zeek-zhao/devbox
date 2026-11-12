---
track: shell
guide: G4
dimensions: [D3, D8]
level: P1
status: draft
links: [知识点清单.md, 实践指南.md, 开发指南.md, 问题指南.md, 工具指南.md, FAQ.md, 错误处理指南.md, 排查手册.md, 工程参考.md]
examples: [E-001-error-taxonomy, E-008-error-reraise, E-015-antipattern-compare, L0-hello]
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-11
---

# Shell 轨道索引（INDEX）

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
| [错误处理指南](错误处理指南.md) | G1（M11 新增） | 错误处理操作动线：分类→创建→匹配→包装→传播→容错→观测 | 写错误处理代码时 |
| [排查手册](排查手册.md) | G3（M11 新增） | E 系 15 节：症状→命令→判据→修复 | 排查错误处理类故障 |
| [工程参考](工程参考.md) | G4（M11 新增） | 镜像/构建/依赖/环境变量/版本真本速查 | 查工程事实 |

## 2. E 系示范用例反查（15 例）

全部位于 `shell/examples/`，运行契约 `TAG=latest scripts/run-example.sh shell <ID>`；
一行速查版在 [知识点清单 §E](知识点清单.md)，逐例正文在各自 README。

| 用例 | 考点关键词 | 主关联文档 |
|---|---|---|
| [E-001-error-taxonomy](../examples/E-001-error-taxonomy/README.md) | 退出码分类体系 | [排查手册](排查手册.md) §2.1 |
| [E-002-error-create](../examples/E-002-error-create/README.md) | 标准化诊断行、类别码 | [排查手册](排查手册.md) §2.2 |
| [E-003-error-match](../examples/E-003-error-match/README.md) | 探测三分支 | [排查手册](排查手册.md) §2.3 |
| [E-004-error-wrap](../examples/E-004-error-wrap/README.md) | 包装保码保上下文 | [排查手册](排查手册.md) §2.4 |
| [E-005-error-identity](../examples/E-005-error-identity/README.md) | 错误身份跨层保持 | [排查手册](排查手册.md) §2.5 |
| [E-006-error-context](../examples/E-006-error-context/README.md) | 上下文链 | [排查手册](排查手册.md) §2.6 |
| [E-007-cleanup-guarantee](../examples/E-007-cleanup-guarantee/README.md) | 清理不顶替业务码 | [排查手册](排查手册.md) §2.7 |
| [E-008-error-reraise](../examples/E-008-error-reraise/README.md) | 记录后重抛 | [排查手册](排查手册.md) §2.8 |
| [E-009-tool-code-boundary](../examples/E-009-tool-code-boundary/README.md) | 工具码边界翻译 | [排查手册](排查手册.md) §2.9 |
| [E-010-retry-backoff](../examples/E-010-retry-backoff/README.md) | 重试分类、指数退避 | [排查手册](排查手册.md) §2.10 |
| [E-011-timeout-deadline](../examples/E-011-timeout-deadline/README.md) | 超时与截止时间 | [排查手册](排查手册.md) §2.11 |
| [E-012-error-aggregate](../examples/E-012-error-aggregate/README.md) | 失败聚合 | [排查手册](排查手册.md) §2.12 |
| [E-013-error-observability](../examples/E-013-error-observability/README.md) | 结构化记录、分流 | [排查手册](排查手册.md) §2.13 |
| [E-014-fail-fast](../examples/E-014-fail-fast/README.md) | 前置校验、副作用为零 | [排查手册](排查手册.md) §2.14 |
| [E-015-antipattern-compare](../examples/E-015-antipattern-compare/README.md) | 四大反模式对照 | [排查手册](排查手册.md) §2.15 |

## 3. 轨道 lab 反查（1 个）

| lab | 故障形态 | 入口 | 判读文档 |
|---|---|---|---|
| T-001-word-splitting-pipefail | 词分割 × 管道中段吞错的组合故障 | `shell/examples/T-001-word-splitting-pipefail/run.sh` | [WALKTHROUGH.md](../examples/T-001-word-splitting-pipefail/WALKTHROUGH.md) |

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
