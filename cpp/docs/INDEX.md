---
track: cpp
guide: reference       # Diátaxis reference（轨道索引）；M11-DOC 新增文档类型，不在 docs/11 §1 的 G1..G5 五类之列
dimensions: [D8]
level: P1
status: draft
links: [知识点清单.md, 错误处理指南.md, 排查手册.md, 工程参考.md]
examples: [L0-hello, E-001-exception-hierarchy, E-015-antipattern-compare]
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-11
---

# C++ 轨道索引（INDEX）

> 反查表：从「我要的东西」反查到具体文件。覆盖本轨 10 篇指南文档、
> 15 个 E 类示例、1 个 lab 与清单 E 段。全站索引归 `docs/INDEX.md`（本卡不改）。

## 1. 指南文档反查（10 篇）

| 文档 | 类型 | 回答的问题 |
|---|---|---|
| [知识点清单](知识点清单.md) | 清单 | 练什么：KP 编号用例清单 + E 段反查表 |
| [实践指南](实践指南.md) | G1 how-to | 什么时候用、不用会怎样、怎么验 |
| [开发指南](开发指南.md) | G2 how-to | 从零到能改：环境、目录、构建、提交动线 |
| [问题指南](问题指南.md) | G3 troubleshooting | 按问题域的疑难：现象 → 假设 → 定位 → 修复 |
| [工具指南](工具指南.md) | G4 reference | sanitizer/gdb 等工具速查与误用 |
| [FAQ](FAQ.md) | G5 reference | 高频短问答 |
| [用例编写规范](用例编写规范.md) | 规范 | 新用例怎么写才算合格 |
| [错误处理指南](错误处理指南.md) | how-to（M11-DOC 新增） | 要把错误处理写对：任务 → 动作 → E 例 → 验证命令 |
| [排查手册](排查手册.md) | troubleshooting（M11-DOC 新增） | 坏了怎么查：症状 → 命令 → 判据 → 修复（§2 逐节对应 E-001..E-015） |
| [工程参考](工程参考.md) | reference（M11-DOC 新增） | 镜像层/版本真本/命令/环境变量/计数口径查表 |

## 2. E 类示例反查（15 个，`cpp/examples/E-0xx-*`）

详细判读统一走 [排查手册](排查手册.md) §2 对应节；本表只做 ID → 考点反查。

| 用例 | 一句话考点 | 排查手册节 |
|---|---|---|
| [E-001-exception-hierarchy](../examples/E-001-exception-hierarchy/README.md) | 异常层次与 catch 分发 | §2.1 |
| [E-002-custom-exception-context](../examples/E-002-custom-exception-context/README.md) | 自定义异常携带上下文字段 | §2.2 |
| [E-003-errno-checking](../examples/E-003-errno-checking/README.md) | errno 检查时机与 system_error | §2.3 |
| [E-004-unwinding-cleanup-order](../examples/E-004-unwinding-cleanup-order/README.md) | 栈展开逆序析构 | §2.4 |
| [E-005-result-value-return](../examples/E-005-result-value-return/README.md) | variant 最小 Result / optional | §2.5 |
| [E-006-error-code-enum](../examples/E-006-error-code-enum/README.md) | 错误码枚举与退出码映射 | §2.6 |
| [E-007-nested-exceptions](../examples/E-007-nested-exceptions/README.md) | 嵌套异常保留因果链 | §2.7 |
| [E-008-strong-guarantee](../examples/E-008-strong-guarantee/README.md) | 强异常保证对照 | §2.8 |
| [E-009-leak-guard](../examples/E-009-leak-guard/README.md) | unique_ptr 守裸句柄 | §2.9 |
| [E-010-contract-assert](../examples/E-010-contract-assert/README.md) | 输入校验与不变式分层 | §2.10 |
| [E-011-structured-logging](../examples/E-011-structured-logging/README.md) | 结构化日志格式 | §2.11 |
| [E-012-retry-backoff](../examples/E-012-retry-backoff/README.md) | 三类重试结局与指数退避 | §2.12 |
| [E-013-error-aggregation](../examples/E-013-error-aggregation/README.md) | 校验错误全量收集 | §2.13 |
| [E-014-fail-fast](../examples/E-014-fail-fast/README.md) | 入口快速失败零副作用 | §2.14 |
| [E-015-antipattern-compare](../examples/E-015-antipattern-compare/README.md) | 吞异常/切片/笼统消息对照 | §2.15 |

清单侧反查表见 [知识点清单](知识点清单.md) `## E` 段（逐行含排查命令与判据）。

## 3. lab 反查（1 个）

| lab | 场景 | 判读文档 |
|---|---|---|
| [T-001-asan-heap-overflow](../labs/T-001-asan-heap-overflow/WALKTHROUGH.md) | 堆越界 + 泄漏：ASan / valgrind / gdb 三工具交叉验证 | `cpp/labs/T-001-asan-heap-overflow/WALKTHROUGH.md` |

## 4. 「我要查 X」反查示例

- 我要练某个语法/工程点 → [知识点清单](知识点清单.md) 按 KP 编号查。
- 我要把错误处理写对 → [错误处理指南](错误处理指南.md) §2 任务路由表。
- 我手上有个故障 → [排查手册](排查手册.md)按症状找节；内存类走 §3 路由。
- 我要查镜像/版本/环境变量 → [工程参考](工程参考.md) §2、§4。
- 我要跑某个用例 → `TAG=latest scripts/run-example.sh cpp <ID>`（契约见
  [工程参考](工程参考.md) §3）。
- 我要做一个排障演练 → [T-001 WALKTHROUGH](../labs/T-001-asan-heap-overflow/WALKTHROUGH.md)，
  规范见 [docs/72](../../docs/72-排障演练规范.md)。
- 我有小疑问 → [FAQ](FAQ.md)；查不到的入口在各篇「相关」节与
  [docs/ROADMAP](../../docs/ROADMAP.md) KI 段。
