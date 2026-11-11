---
title: 全站文档索引（INDEX）
date: 2026-11-12
status: draft
scope: docs/ 顶层与 9 轨 docs/ 的全量索引 / 仅文档
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-12
---

# 全站文档索引

> 覆盖顶层 `docs/` 全部 md 与 9 轨 `docs/` 全部 md；全部为仓库相对路径，
> 可用 `test -f` 逐条核验（核验命令见 §3）。
> 按象限找文档看 [84-文档地图](84-文档地图.md)，按用例反查看
> [INDEX-by-example](INDEX-by-example.md)，按症状排查看 [83-排障总入口](83-排障总入口.md)。

## 1. 保鲜契约：脚本生成，禁手写保鲜

- 本文件是**生成物**，不是创作物。首版由 M11-G 任务卡按本契约人工生成；
  M12-CI 的 `scripts/build-doc-index.sh`（issue #339）交付后，改由脚本全量重生成。
- **禁止**为「追平」文档增删而手改本文件：新增/删除/改名文档后，跑脚本重生成
  （脚本交付前，由对应任务卡在卡内按本契约重生成并在 issue 留痕）。
- 手写只允许修复本文件自身的错误（死链、错误 status），且必须在 issue 卡留证据。
- 字段来源表（重生成时脚本也按此取值）：

| 字段 | 来源 | 缺省 |
|---|---|---|
| 文档名 | 仓库相对路径（相对本文件所在 `docs/`） | — |
| 说明 | 该文档 frontmatter 的 `title`；无 frontmatter 取首个 `# ` 标题 | 「（无标题）」 |
| status | 该文档 frontmatter 的 `status` | `draft` |
| 本文件 status | 本文件 frontmatter 的 `status` | `draft` |

- status 词表**只用** `draft` / `reviewed` / `verified`（[75-文档健康规范](75-文档健康规范.md)
  状态机；无 frontmatter 的篇一律按 `draft` 计入，不得发明「未标注」等第四态）。

## 2. 顶层 docs/（33 篇）

| 文档 | 说明 | status |
|---|---|---|
| [00-文档总览](00-文档总览.md) | devbox 文档总览（学习维度增强版） | reviewed |
| [01-镜像体系](01-镜像体系.md) | 镜像体系 | draft |
| [02-流水线](02-流水线.md) | 流水线 | draft |
| [10-多维度学习模型](10-多维度学习模型.md) | 多维度语言学习模型 | reviewed |
| [11-知识点清单增强规范](11-知识点清单增强规范.md) | 知识点清单增强规范（指南层） | reviewed |
| [12-语言指南覆盖矩阵](12-语言指南覆盖矩阵.md) | 语言指南覆盖矩阵 | reviewed |
| [13-通用开发指南](13-通用开发指南.md) | 通用开发指南（T0 骨架） | draft |
| [20-开发发布增强](20-开发发布增强.md) | 开发发布维度增强（通用框架 + 分语言） | draft |
| [21-发布工程七域](21-发布工程七域.md) | 发布工程七域（R1–R7 现状与差距） | draft |
| [24-G3素材池](24-G3素材池.md) | G3 真实排查素材池 | draft |
| [30-GitHub现状与时限](30-GitHub现状与时限.md) | GitHub 现状与时限情况（本地快照） | reviewed |
| [40-问题清单](40-问题清单.md) | 优化问题清单 | reviewed |
| [41-里程碑拆分](41-里程碑拆分.md) | 里程碑拆分（问题清单 → 里程碑 → 卡） | reviewed |
| [50-迁移对照与取舍](50-迁移对照与取舍.md) | 旧文档迁移对照与取舍 | reviewed |
| [60-AI工作指南](60-AI工作指南.md) | AI 工作指南 | reviewed |
| [70-并行AI开发计划](70-并行AI开发计划.md) | 并行 AI 开发计划（一卡一目录一分支一 PR） | reviewed |
| [71-任务卡规范v2](71-任务卡规范v2.md) | 任务卡规范 v2（agent_task 表单的规范真本） | draft |
| [72-排障演练规范](72-排障演练规范.md) | 排障演练规范（可执行 lab） | draft |
| [73-M11并发执行计划](73-M11并发执行计划.md) | M11 并发执行计划（文档增强 v2） | reviewed |
| [75-文档健康规范](75-文档健康规范.md) | 文档健康规范（frontmatter owner 与保鲜） | draft |
| [76-M11派单状态](76-M11派单状态.md) | M11 派单状态表（coordinator 元卡） | draft |
| [78-CI失败分类规范](78-CI失败分类规范.md) | CI 失败分类规范（infra_transient / real_regression / flaky_test） | draft |
| [79-文档健康清单](79-文档健康清单.md) | 文档健康 advisory 清单 | draft |
| [80-M12度量规范](80-M12度量规范.md) | M12 度量规范（四指标与 m12-traces schema） | draft |
| [81-错误处理四模型与分类法](81-错误处理四模型与分类法.md) | 错误处理四模型与分类法（解释） | draft |
| [82-错误码与错误结构](82-错误码与错误结构.md) | 错误码与错误结构（How-to / 契约） | draft |
| [83-排障总入口](83-排障总入口.md) | 排障总入口（How-to） | draft |
| [84-文档地图](84-文档地图.md) | 文档地图（Reference） | draft |
| [85-CI增强规格](85-CI增强规格.md) | CI 增强规格（给 #264 的施工图） | draft |
| [86-度量口径](86-度量口径.md) | 86 度量口径（仓库资产侧六指标） | draft |
| [87-CI失败取证规范](87-CI失败取证规范.md) | CI 失败取证规范（日志下载、artifact 留档与 step summary） | draft |
| [ROADMAP](ROADMAP.md) | 路线图与里程碑 | draft |
| [开源合规审计](开源合规审计.md) | 开源合规审计报告 | draft |

## 3. 各轨 docs/

> 每轨一行的全量文件索引；轨内文件集因轨而异（如实列出，不凑齐）。

| 轨道 | 文件 |
|---|---|
| c | [FAQ](../c/docs/FAQ.md) · [INDEX](../c/docs/INDEX.md) · [实践指南](../c/docs/实践指南.md) · [工具指南](../c/docs/工具指南.md) · [工程参考](../c/docs/工程参考.md) · [开发指南](../c/docs/开发指南.md) · [排查手册](../c/docs/排查手册.md) · [用例编写规范](../c/docs/用例编写规范.md) · [知识点清单](../c/docs/知识点清单.md) · [错误处理指南](../c/docs/错误处理指南.md) · [问题指南](../c/docs/问题指南.md) |
| cpp | [FAQ](../cpp/docs/FAQ.md) · [INDEX](../cpp/docs/INDEX.md) · [实践指南](../cpp/docs/实践指南.md) · [工具指南](../cpp/docs/工具指南.md) · [工程参考](../cpp/docs/工程参考.md) · [开发指南](../cpp/docs/开发指南.md) · [排查手册](../cpp/docs/排查手册.md) · [用例编写规范](../cpp/docs/用例编写规范.md) · [知识点清单](../cpp/docs/知识点清单.md) · [错误处理指南](../cpp/docs/错误处理指南.md) · [问题指南](../cpp/docs/问题指南.md) |
| go | [FAQ](../go/docs/FAQ.md) · [INDEX](../go/docs/INDEX.md) · [实践指南](../go/docs/实践指南.md) · [工具指南](../go/docs/工具指南.md) · [工程参考](../go/docs/工程参考.md) · [开发指南](../go/docs/开发指南.md) · [排查手册](../go/docs/排查手册.md) · [清单自检](../go/docs/清单自检.md) · [知识点清单](../go/docs/知识点清单.md) · [错误处理指南](../go/docs/错误处理指南.md) · [问题指南](../go/docs/问题指南.md) |
| rust | [FAQ](../rust/docs/FAQ.md) · [INDEX](../rust/docs/INDEX.md) · [实践指南](../rust/docs/实践指南.md) · [工具指南](../rust/docs/工具指南.md) · [工程参考](../rust/docs/工程参考.md) · [开发指南](../rust/docs/开发指南.md) · [排查手册](../rust/docs/排查手册.md) · [清单自检](../rust/docs/清单自检.md) · [知识点清单](../rust/docs/知识点清单.md) · [错误处理指南](../rust/docs/错误处理指南.md) · [问题指南](../rust/docs/问题指南.md) |
| shell | [FAQ](../shell/docs/FAQ.md) · [INDEX](../shell/docs/INDEX.md) · [实践指南](../shell/docs/实践指南.md) · [工具指南](../shell/docs/工具指南.md) · [工程参考](../shell/docs/工程参考.md) · [开发指南](../shell/docs/开发指南.md) · [排查手册](../shell/docs/排查手册.md) · [清单自检](../shell/docs/清单自检.md) · [知识点清单](../shell/docs/知识点清单.md) · [错误处理指南](../shell/docs/错误处理指南.md) · [问题指南](../shell/docs/问题指南.md) |
| python | [FAQ](../python/docs/FAQ.md) · [INDEX](../python/docs/INDEX.md) · [实践指南](../python/docs/实践指南.md) · [工具指南](../python/docs/工具指南.md) · [工程参考](../python/docs/工程参考.md) · [开发指南](../python/docs/开发指南.md) · [排查手册](../python/docs/排查手册.md) · [清单自检](../python/docs/清单自检.md) · [知识点清单](../python/docs/知识点清单.md) · [错误处理指南](../python/docs/错误处理指南.md) · [问题指南](../python/docs/问题指南.md) |
| java | [FAQ](../java/docs/FAQ.md) · [INDEX](../java/docs/INDEX.md) · [实践指南](../java/docs/实践指南.md) · [工具指南](../java/docs/工具指南.md) · [工程参考](../java/docs/工程参考.md) · [开发指南](../java/docs/开发指南.md) · [排查手册](../java/docs/排查手册.md) · [清单自检](../java/docs/清单自检.md) · [知识点清单](../java/docs/知识点清单.md) · [错误处理指南](../java/docs/错误处理指南.md) · [问题指南](../java/docs/问题指南.md) |
| vue | [FAQ](../vue/docs/FAQ.md) · [INDEX](../vue/docs/INDEX.md) · [实践指南](../vue/docs/实践指南.md) · [工具指南](../vue/docs/工具指南.md) · [工程参考](../vue/docs/工程参考.md) · [开发指南](../vue/docs/开发指南.md) · [排查手册](../vue/docs/排查手册.md) · [用例编写规范](../vue/docs/用例编写规范.md) · [知识点清单](../vue/docs/知识点清单.md) · [错误处理指南](../vue/docs/错误处理指南.md) · [问题指南](../vue/docs/问题指南.md) |
| db | [INDEX](../db/docs/INDEX.md) · [实践指南](../db/docs/实践指南.md) · [排查手册](../db/docs/排查手册.md) · [知识点清单](../db/docs/知识点清单.md) · [问题指南](../db/docs/问题指南.md) |

### 死链核验

本节所有链接可用下方命令核验（逐条 `test -f`，输出应为空）：

```bash
grep -oE '\]\((\.\./[a-z]+/docs/[^)]+|[A-Za-z0-9_.-]+\.md)\)' docs/INDEX.md \
  | sed -E 's/^\]\(//; s/\)$//' \
  | while read -r p; do case "$p" in ../*) t="$p";; *) t="docs/$p";; esac; \
    [ -f "$t" ] || echo "DEAD: $p"; done
```

> 本文件不使用 `<!-- verify: -->` 标记：核验由审阅者按需执行，
> 上方命令即完整可粘贴脚本。

## 4. 相关

- [84-文档地图](84-文档地图.md)：同一批文档的四象限视图
- [75-文档健康规范](75-文档健康规范.md)：status 词表与保鲜规则的真本
- [INDEX-by-example](INDEX-by-example.md)：按用例 ID 反查（另一维度）
