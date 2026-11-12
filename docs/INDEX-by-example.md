---
title: 按用例反查索引（INDEX-by-example）
date: 2026-11-12
status: draft
scope: 从用例 ID 反查清单锚点 / 指南节 / lab / 排查命令 / 仅文档
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-12
---

# 按用例反查索引（规范 + 样例）

> 正向索引是「文档 → 用例」（[INDEX](INDEX.md)）；本文件是**反查索引**：
> 你手里只有一个用例 ID（CI 失败、coverage 报告、`run-example.sh` 输出），
> 要找到它挂在哪份清单、哪节指南、哪个 lab。
> 本文交付**规范与 3 条样例行**；全量行由脚本生成，**禁手写全量**（§3）。

## 1. 行规范

每行 9 个字段，字段来源：

| 字段 | 含义 | 来源 |
|---|---|---|
| 用例 ID | `examples/` 目录名 | `ls <track>/examples/` |
| 轨道 | 9 轨之一（c/cpp/go/rust/shell/python/java/vue/db） | 目录一级名 |
| 层级 | L0/L1/L2/L3/L4/E（E 亦称 E 类用例） | ID 前缀 |
| E 类 | E 行专有：该 E 例覆盖的错误处理主题（对应 [81 §3](81-错误处理四模型与分类法.md) 五分类）；非 E 行填 `—` | `<track>/docs/知识点清单.md` §E 行 |
| 清单锚点 | 知识点清单中的行锚点（KP 编号或 E-ID） | `<track>/docs/知识点清单.md` |
| 指南节 | 讲解该知识点的指南文档（文件级；节号仅在有明确锚时写） | `<track>/docs/` 各指南 |
| lab | 关联的排障演练 lab（`<track>/examples/T-001-*`）；无则 `—` | `examples/` 目录 |
| 排查命令 | 可原样粘贴的复现命令 | `TAG=latest scripts/run-example.sh <轨道> <用例ID>` |
| coverage 状态 | `covered`（默认）/ `pending` / `exempt <原因>` | 该用例 `README.md` 的 `coverage:` 声明（[scripts/coverage-check.sh](../scripts/coverage-check.sh) 判定） |

- ID 真实性判据：**每个用例 ID 必须对应真实存在的 `examples/` 目录**；
  清单锚点必须能在对应知识点清单里 grep 到。两者机器可核（§3 的核验命令）。

## 2. 样例行（go 轨，3 行覆盖 L1 / L2 / E 各层级）

| 用例 ID | 轨道 | 层级 | E 类 | 清单锚点 | 指南节 | lab | 排查命令 | coverage 状态 |
|---|---|---|---|---|---|---|---|---|
| L1-001-package-exports | go | L1 | — | [KP-GO-L1-01](../go/docs/知识点清单.md) | [go/docs/实践指南.md](../go/docs/实践指南.md) §2（最小可运行示例） | — | `TAG=latest scripts/run-example.sh go L1-001-package-exports` | covered |
| L2-001-local-module-replace | go | L2 | — | [KP-GO-L2-01](../go/docs/知识点清单.md) | [go/docs/实践指南.md](../go/docs/实践指南.md)（frontmatter `examples` 含此 ID） | — | `TAG=latest scripts/run-example.sh go L2-001-local-module-replace` | covered |
| E-011-context-timeout | go | E | 超时与取消（transient/system 边界） | [E-011-context-timeout](../go/docs/知识点清单.md) | [go/docs/排查手册.md](../go/docs/排查手册.md) §2.11 · [go/docs/错误处理指南.md](../go/docs/错误处理指南.md) §2.6 | [T-001-goroutine-leak](../go/examples/T-001-goroutine-leak/WALKTHROUGH.md) | `TAG=latest scripts/run-example.sh go E-011-context-timeout` | covered |

> 样例判据：3 个 ID 均对应真实目录（`go/examples/L1-001-package-exports`、
> `go/examples/L2-001-local-module-replace`、`go/examples/E-011-context-timeout`）；
> E 行的排查命令与判据原文取自 go 知识点清单 §E 对应行，不另造。

## 3. 保鲜契约：脚本生成，禁手写全量

- 10 轨共 804 个 examples 目录（存量 659 + E 类 135 + 演练 10，[ROADMAP](ROADMAP.md) 口径）。
  任何 **659→804 之后**的增量（新增轨、新增 E 例、新增演练）都按本节契约进入本索引。
- 全量行**只能由脚本生成**（M12-CI 的 `build-doc-index.sh`，issue #339 交付后生效；
  交付前新行由对应任务卡按 §1 字段表生成并在 issue 留核验输出）。
- 禁止手写全量清单来「补齐」——手写必然腐烂：ID 改名、coverage 翻转、
  指南节号漂移都不会自动同步。手写只允许出现于：规范、样例行、以及脚本输出的人工校正
  （校正必须同时在用例或清单源头修，不能只改索引）。
- 机器核验（无死锚、无幻 ID，输出应为空）：

```bash
grep -oE '\| (KP-[A-Z]+-L[0-9]+-[0-9]+|L[0-9]+-[0-9]+-[a-z0-9-]+|E-[0-9]+-[a-z0-9-]+) \|' docs/INDEX-by-example.md \
  | tr -d '| ' | while read -r id; do
    case "$id" in
      KP-*) grep -qm1 "^| $id " go/docs/知识点清单.md || echo "DEAD-ANCHOR: $id";;
      E-*) grep -qm1 "^| $id " go/docs/知识点清单.md || echo "DEAD-ANCHOR: $id";;
      L*)   [ -d "go/examples/$id" ] || echo "PHANTOM: $id";;
    esac; done
```

> 本文件不使用 `<!-- verify: -->` 标记：样例行一次生成、随卡验收，
> 全量核验由脚本与 CI 承担，不在每次文档门禁里重复执行。

## 4. 相关

- [INDEX](INDEX.md)：按文档名的正向索引
- [84-文档地图](84-文档地图.md)：文档的象限定位
- [81-错误处理四模型与分类法](81-错误处理四模型与分类法.md)：E 类字段的分类依据
- [83-排障总入口](83-排障总入口.md)：拿到排查命令之后的入口
