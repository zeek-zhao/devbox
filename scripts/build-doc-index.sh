#!/usr/bin/env bash
# scripts/build-doc-index.sh — 三层文档索引生成器（M12-CI-03，issue #339）
#
# 从目录名与 frontmatter 生成三层索引（字段契约：docs/INDEX.md §1 保鲜契约、
# docs/INDEX-by-example.md §1 行规范，由 M11-G #333/#334 定）：
#   1. docs/INDEX.md            —— §2 顶层表（title/status 从各文档 frontmatter 派生，
#                                  无 frontmatter 取首个 `# ` 标题，status 缺省 draft）
#                                  与 §3 各轨文件行（从 <track>/docs/ 目录名派生）为动态生成；
#                                  其余 prose 固化在本脚本模板中（脚本即生成源，禁手改索引）。
#   2. <track>/docs/INDEX.md ×9 —— 轨内 curated 字段（一句话职责/考点关键词等）不可从
#                                  frontmatter 派生，整篇固化为本脚本模板；改内容改这里再重生成。
#   3. docs/INDEX-by-example.md —— 同上，规范 + 样例行固化；全量行本就「禁手写」。
#
# 用法：
#   bash scripts/build-doc-index.sh            # 就地重生成 11 个文件
#   bash scripts/build-doc-index.sh --check    # 重生成到临时目录后与工作树 diff，
#                                              # 有差异打印 DRIFT 并退出 1（git diff --exit-code 语义）
#
# 排序契约：顶层表按文件名字节序（LC_ALL=C sort，排除本文件与 INDEX-by-example.md）；
# 各轨行按固定轨道序 c cpp go rust shell python java vue db，轨内按
# FAQ/INDEX/实践指南/工具指南/工程参考/开发指南/排查手册/清单自检|用例编写规范/
# 知识点清单/错误处理指南/问题指南 的优先序（未知文件缀后）。
set -euo pipefail

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1
[ $# -gt 1 ] && { echo "用法: $0 [--check]" >&2; exit 2; }

ROOT=$(git rev-parse --show-toplevel)
TMP=""
cleanup() { [ -n "$TMP" ] && rm -rf "$TMP"; return 0; }
trap cleanup EXIT
if [ "$CHECK" = 1 ]; then TMP=$(mktemp -d); DEST="$TMP"; else DEST="$ROOT"; fi

TRACKS="c cpp go rust shell python java vue db"

# fm_field <file> <key>: 取 frontmatter 字段值；无 frontmatter 或无该字段输出空
fm_field() {
  awk -v k="$2:" 'NR==1 && $0=="---" {fm=1; next}
                  fm && /^---$/ {exit}
                  fm && index($0, k)==1 {v=substr($0, length(k)+1); sub(/^ */, "", v); print v; exit}' "$1"
}

# 顶层 docs/ 表：字节序遍历，排除两个生成物自身
gen_top_rows() {
  local f name title status
  while IFS= read -r f; do
    name=$(basename "$f" .md)
    title=$(fm_field "$f" title)
    if [ -z "$title" ]; then title=$(awk '/^# /{sub(/^# /,""); print; exit}' "$f"); fi
    [ -z "$title" ] && title=（无标题）
    status=$(fm_field "$f" status); [ -z "$status" ] && status=draft
    printf '| [%s](%s.md) | %s | %s |\n' "$name" "$name" "$title" "$status"
  done < <(printf '%s\n' "$ROOT"/docs/*.md | LC_ALL=C sort | grep -vE '/(INDEX|INDEX-by-example)\.md$')
}

# 各轨文件行：固定轨道序 + 轨内优先序（未知文件缀后，按字节序）
gen_track_rows() {
  local t f name p rows links
  for t in $TRACKS; do
    rows=$(for f in "$ROOT/$t"/docs/*.md; do
      name=$(basename "$f" .md)
      case "$name" in
        FAQ) p=01;; INDEX) p=02;; 实践指南) p=03;; 工具指南) p=04;; 工程参考) p=05;;
        开发指南) p=06;; 排查手册) p=07;; 清单自检|用例编写规范) p=08;;
        知识点清单) p=09;; 错误处理指南) p=10;; 问题指南) p=11;; *) p=99;;
      esac
      printf '%s %s\n' "$p" "$name"
    done | LC_ALL=C sort)
    links=$(printf '%s\n' "$rows" | awk -v t="$t" \
      '{printf "%s[%s](../%s/docs/%s.md)", (NR>1?" · ":""), $2, t, $2}')
    printf '| %s | %s |\n' "$t" "$links"
  done
}

gen_site_index() {
  local n
  n=$(printf '%s\n' "$ROOT"/docs/*.md | LC_ALL=C sort | grep -cvE '/(INDEX|INDEX-by-example)\.md$')
  {
  cat <<'__BDI_EOF_SITE_HEAD__'
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

__BDI_EOF_SITE_HEAD__
  printf '## 2. 顶层 docs/（%d 篇）\n\n' "$n"
  cat <<'__BDI_EOF_SITE_SEC2_HEADER__'
| 文档 | 说明 | status |
|---|---|---|
__BDI_EOF_SITE_SEC2_HEADER__
  gen_top_rows
  printf '\n'
  cat <<'__BDI_EOF_SITE_SEC3_HEAD__'
## 3. 各轨 docs/

> 每轨一行的全量文件索引；轨内文件集因轨而异（如实列出，不凑齐）。

| 轨道 | 文件 |
|---|---|
__BDI_EOF_SITE_SEC3_HEAD__
  gen_track_rows
  cat <<'__BDI_EOF_SITE_TAIL__'

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
__BDI_EOF_SITE_TAIL__
  } > "$DEST/docs/INDEX.md"
}

gen_byexample() {
  cat <<'__BDI_EOF_TPL_BYEXAMPLE__' > "$DEST/docs/INDEX-by-example.md"
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
| lab | 关联的排障演练 lab（`<track>/labs/T-001-*`）；无则 `—` | `labs/` 目录 |
| 排查命令 | 可原样粘贴的复现命令 | `TAG=latest scripts/run-example.sh <轨道> <用例ID>` |
| coverage 状态 | `covered`（默认）/ `pending` / `exempt <原因>` | 该用例 `README.md` 的 `coverage:` 声明（[scripts/coverage-check.sh](../scripts/coverage-check.sh) 判定） |

- ID 真实性判据：**每个用例 ID 必须对应真实存在的 `examples/` 目录**；
  清单锚点必须能在对应知识点清单里 grep 到。两者机器可核（§3 的核验命令）。

## 2. 样例行（go 轨，3 行覆盖 L1 / L2 / E 各层级）

| 用例 ID | 轨道 | 层级 | E 类 | 清单锚点 | 指南节 | lab | 排查命令 | coverage 状态 |
|---|---|---|---|---|---|---|---|---|
| L1-001-package-exports | go | L1 | — | [KP-GO-L1-01](../go/docs/知识点清单.md) | [go/docs/实践指南.md](../go/docs/实践指南.md) §2（最小可运行示例） | — | `TAG=latest scripts/run-example.sh go L1-001-package-exports` | covered |
| L2-001-local-module-replace | go | L2 | — | [KP-GO-L2-01](../go/docs/知识点清单.md) | [go/docs/实践指南.md](../go/docs/实践指南.md)（frontmatter `examples` 含此 ID） | — | `TAG=latest scripts/run-example.sh go L2-001-local-module-replace` | covered |
| E-011-context-timeout | go | E | 超时与取消（transient/system 边界） | [E-011-context-timeout](../go/docs/知识点清单.md) | [go/docs/排查手册.md](../go/docs/排查手册.md) §2.11 · [go/docs/错误处理指南.md](../go/docs/错误处理指南.md) §2.6 | [T-001-goroutine-leak](../go/labs/T-001-goroutine-leak/WALKTHROUGH.md) | `TAG=latest scripts/run-example.sh go E-011-context-timeout` | covered |

> 样例判据：3 个 ID 均对应真实目录（`go/examples/L1-001-package-exports`、
> `go/examples/L2-001-local-module-replace`、`go/examples/E-011-context-timeout`）；
> E 行的排查命令与判据原文取自 go 知识点清单 §E 对应行，不另造。

## 3. 保鲜契约：脚本生成，禁手写全量

- 9 轨共 794 个用例（存量 659 + E 类 135，[ROADMAP](ROADMAP.md) 口径）。
  任何 **659→794 之后**的增量（新增轨、新增 E 例、新增 lab）都按本节契约进入本索引。
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
__BDI_EOF_TPL_BYEXAMPLE__
}

main() {
  mkdir -p "$DEST/docs"
  for t in $TRACKS; do mkdir -p "$DEST/$t/docs"; done
  gen_site_index
  gen_byexample
  cat <<'__BDI_EOF_TPL_c__' > "$DEST/c/docs/INDEX.md"
---
track: c
guide: reference       # Diátaxis reference（轨道索引）；M11-DOC 新增文档类型，不在 docs/11 §1 的 G1..G5 五类之列
dimensions: [D8]
level: P1
status: draft
links: [知识点清单.md, 错误处理指南.md, 排查手册.md, 工程参考.md]
examples: [L0-hello, E-001-error-taxonomy, E-015-antipattern-compare]
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-11
---

# C 轨道索引（INDEX）

> 反查表：从「我要的东西」反查到具体文件。覆盖本轨 10 篇指南文档、
> 15 个 E 类示例、1 个 lab 与清单 E 段。全站索引归 `docs/INDEX.md`（本卡不改）。

## 1. 指南文档反查（10 篇）

| 文档 | 类型 | 回答的问题 |
|---|---|---|
| [知识点清单](知识点清单.md) | 清单 | 练什么：L0/L1/L2/L3 用例 ID 清单 + E 段反查表 |
| [实践指南](实践指南.md) | G1 how-to | 什么时候用、不用会怎样、怎么验 |
| [开发指南](开发指南.md) | G2 how-to | 从零到能改：环境、目录、构建、提交动线 |
| [问题指南](问题指南.md) | G3 troubleshooting | 按问题域的疑难：现象 → 假设 → 定位 → 修复 |
| [工具指南](工具指南.md) | G4 reference | ASan/UBSan/valgrind/gdb 等工具速查与误用 |
| [FAQ](FAQ.md) | G5 reference | 高频短问答 |
| [用例编写规范](用例编写规范.md) | 规范 | 新用例怎么写才算合格 |
| [错误处理指南](错误处理指南.md) | how-to（M11-DOC 新增） | 要把错误处理写对：任务 → 动作 → E 例 → 验证命令 |
| [排查手册](排查手册.md) | troubleshooting（M11-DOC 新增） | 坏了怎么查：症状 → 命令 → 判据 → 修复（§2 逐节对应 E-001..E-015） |
| [工程参考](工程参考.md) | reference（M11-DOC 新增） | 镜像层/版本真本/命令/环境变量/计数口径查表 |

## 2. E 类示例反查（15 个，`c/examples/E-0xx-*`）

详细判读统一走 [排查手册](排查手册.md) §2 对应节；本表只做 ID → 考点反查。

| 用例 | 一句话考点 | 排查手册节 |
|---|---|---|
| [E-001-error-taxonomy](../examples/E-001-error-taxonomy/README.md) | 错误分类与类型体系 | §2.1 |
| [E-002-error-create](../examples/E-002-error-create/README.md) | 错误值构造（code/what/detail） | §2.2 |
| [E-003-error-match](../examples/E-003-error-match/README.md) | 捕获与精确匹配 | §2.3 |
| [E-004-error-wrap](../examples/E-004-error-wrap/README.md) | 传播与包装（只加前缀不改码） | §2.4 |
| [E-005-error-identity](../examples/E-005-error-identity/README.md) | 错误身份判定（比码不比文案） | §2.5 |
| [E-006-error-context](../examples/E-006-error-context/README.md) | 错误上下文附加（KV 字段） | §2.6 |
| [E-007-goto-cleanup](../examples/E-007-goto-cleanup/README.md) | 资源清理（goto 统一出口） | §2.7 |
| [E-008-error-reraise](../examples/E-008-error-reraise/README.md) | 不吞错与重抛 | §2.8 |
| [E-009-errno-boundary](../examples/E-009-errno-boundary/README.md) | 边界转换与错误码映射 | §2.9 |
| [E-010-retry-backoff](../examples/E-010-retry-backoff/README.md) | 重试与退避 | §2.10 |
| [E-011-deadline-cancel](../examples/E-011-deadline-cancel/README.md) | 超时与取消 | §2.11 |
| [E-012-error-aggregate](../examples/E-012-error-aggregate/README.md) | 并发错误聚合 | §2.12 |
| [E-013-error-observability](../examples/E-013-error-observability/README.md) | 可观测性（结构化事件与计数） | §2.13 |
| [E-014-fail-fast](../examples/E-014-fail-fast/README.md) | 不可恢复与快速失败 | §2.14 |
| [E-015-antipattern-compare](../examples/E-015-antipattern-compare/README.md) | 反模式对照（吞错 vs 显式上抛） | §2.15 |

清单侧反查表见 [知识点清单](知识点清单.md) `## E` 段（逐行含排查命令与判据）。

## 3. lab 反查（1 个）

| lab | 场景 | 判读文档 |
|---|---|---|
| [T-001-oob-double-free](../labs/T-001-oob-double-free/WALKTHROUGH.md) | 堆越界 + 双重释放：ASan（含 recover）/ valgrind / gdb 三工具交叉验证 | `c/labs/T-001-oob-double-free/WALKTHROUGH.md` |

## 4. 「我要查 X」反查示例

- 我要练某个语法点 → [知识点清单](知识点清单.md) L1/L2/L3 段按 ID 查。
- 我要把错误处理写对 → [错误处理指南](错误处理指南.md) §2 任务路由表。
- 我手上有个故障 → [排查手册](排查手册.md)按症状找节；内存类走 §3 路由。
- 我要查镜像/版本/环境变量 → [工程参考](工程参考.md) §2、§4。
- 我要跑某个用例 → `TAG=latest scripts/run-example.sh c <ID>`（契约见
  [工程参考](工程参考.md) §3）。
- 我要做一个排障演练 → [T-001 WALKTHROUGH](../labs/T-001-oob-double-free/WALKTHROUGH.md)，
  规范见 [docs/72](../../docs/72-排障演练规范.md)。
- 我有小疑问 → [FAQ](FAQ.md)；查不到的入口在各篇「相关」节与
  [docs/ROADMAP](../../docs/ROADMAP.md) KI 段。
__BDI_EOF_TPL_c__

  cat <<'__BDI_EOF_TPL_cpp__' > "$DEST/cpp/docs/INDEX.md"
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
__BDI_EOF_TPL_cpp__

  cat <<'__BDI_EOF_TPL_go__' > "$DEST/go/docs/INDEX.md"
---
track: go
guide: G4
dimensions: [D3, D8]
level: P1
status: draft
links: [知识点清单.md, 实践指南.md, 开发指南.md, 问题指南.md, 工具指南.md, FAQ.md, 错误处理指南.md, 排查手册.md, 工程参考.md]
examples: [E-001-error-taxonomy, E-011-context-timeout, E-015-antipattern-compare, L0-hello]
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-12
---

# Go 轨道索引（INDEX）

> 本文只有一个主要承诺：**反查**。从任何一篇文档、一个 E 系用例或一个 lab 出发，
> 都能在这里找到它属于哪条学习线、下一步去哪。本文不含正文，全部条目外链到对应文件。

## 1. 指南层反查（7 篇既有指南 + 3 篇 M11 新增）

| 文件 | 类型 | 一句话职责 | 什么时候打开 |
|---|---|---|---|
| [知识点清单](知识点清单.md) | 清单 | L1–L4 用例 ID 清单 + E 系反查表（§E） | 「练什么」 |
| [清单自检](清单自检.md) | 自检 | 探针式逐 KP 快速自测 | 怀疑某个 KP 没学会 |
| [实践指南](实践指南.md) | G1 | 知识点放进真实任务：何时用/不用会怎样 | 想把 KP 用起来 |
| [开发指南](开发指南.md) | G2 | 环境到提交的完整动线 | 从零开始动手 |
| [问题指南](问题指南.md) | G3 | 按问题域组织疑难：现象→假设→定位→修复 | 卡在一个具体故障（语言层） |
| [工具指南](工具指南.md) | G4 | 工具清单、调用、参数速查 | 查工具用法 |
| [FAQ](FAQ.md) | G5 | 高频短问答 | 10 秒内想要答案 |
| [错误处理指南](错误处理指南.md) | G1（M11 新增） | 错误处理操作动线：分类→创建→匹配→包装→容错→边界→报告 | 写错误处理代码时 |
| [排查手册](排查手册.md) | G3（M11 新增） | E 系 15 节：症状→命令→判据→修复 | 排查错误处理类故障 |
| [工程参考](工程参考.md) | G4（M11 新增） | 镜像/构建/依赖/环境变量/版本真本速查 | 查工程事实 |

## 2. E 系示范用例反查（15 例）

全部位于 `go/examples/`，运行契约 `TAG=latest scripts/run-example.sh go <ID>`；
一行速查版在 [知识点清单 §E](知识点清单.md)，逐例正文在各自 README。

| 用例 | 考点关键词 | 主关联文档 |
|---|---|---|
| [E-001-error-taxonomy](../examples/E-001-error-taxonomy/README.md) | 错误分类、类别→动作 | [排查手册](排查手册.md) §2.1 |
| [E-002-error-create](../examples/E-002-error-create/README.md) | 创建现场、typed-nil 陷阱 | [排查手册](排查手册.md) §2.2 |
| [E-003-error-match](../examples/E-003-error-match/README.md) | `==` vs `errors.Is`、自定义 Is | [排查手册](排查手册.md) §2.3 |
| [E-004-error-wrap](../examples/E-004-error-wrap/README.md) | `%w` 保链、`%v` 断链 | [排查手册](排查手册.md) §2.4 |
| [E-005-error-identity](../examples/E-005-error-identity/README.md) | 哨兵身份、`errors.As` 取字段 | [排查手册](排查手册.md) §2.5 |
| [E-006-error-context](../examples/E-006-error-context/README.md) | 逐层上下文、数据引号 | [排查手册](排查手册.md) §2.6 |
| [E-007-defer-cleanup](../examples/E-007-defer-cleanup/README.md) | defer 清理、双错误共存 | [排查手册](排查手册.md) §2.7 |
| [E-008-error-reraise](../examples/E-008-error-reraise/README.md) | 吞错=假成功、重抛保身份 | [排查手册](排查手册.md) §2.8 |
| [E-009-errno-boundary](../examples/E-009-errno-boundary/README.md) | 系统边界、退出码协议 | [排查手册](排查手册.md) §2.9 |
| [E-010-retry-backoff](../examples/E-010-retry-backoff/README.md) | 分类重试、指数退避 | [排查手册](排查手册.md) §2.10 |
| [E-011-context-timeout](../examples/E-011-context-timeout/README.md) | deadline vs cancel | [排查手册](排查手册.md) §2.11 |
| [E-012-error-join](../examples/E-012-error-join/README.md) | 并发聚合、成员身份 | [排查手册](排查手册.md) §2.12 |
| [E-013-error-observability](../examples/E-013-error-observability/README.md) | 只记一次、日志后身份可判 | [排查手册](排查手册.md) §2.13 |
| [E-014-fail-fast](../examples/E-014-fail-fast/README.md) | 不变量、panic 转 error | [排查手册](排查手册.md) §2.14 |
| [E-015-antipattern-compare](../examples/E-015-antipattern-compare/README.md) | 四大反模式对照 | [排查手册](排查手册.md) §2.15 |

## 3. 轨道 lab 反查（1 个）

| lab | 故障形态 | 入口 | 判读文档 |
|---|---|---|---|
| T-001-goroutine-leak | goroutine 泄漏：无超时/无取消的阻塞等待 | `go/labs/T-001-goroutine-leak/run.sh` | [WALKTHROUGH.md](../labs/T-001-goroutine-leak/WALKTHROUGH.md) |

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
__BDI_EOF_TPL_go__

  cat <<'__BDI_EOF_TPL_rust__' > "$DEST/rust/docs/INDEX.md"
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
__BDI_EOF_TPL_rust__

  cat <<'__BDI_EOF_TPL_shell__' > "$DEST/shell/docs/INDEX.md"
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
| T-001-word-splitting-pipefail | 词分割 × 管道中段吞错的组合故障 | `shell/labs/T-001-word-splitting-pipefail/run.sh` | [WALKTHROUGH.md](../labs/T-001-word-splitting-pipefail/WALKTHROUGH.md) |

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
__BDI_EOF_TPL_shell__

  cat <<'__BDI_EOF_TPL_python__' > "$DEST/python/docs/INDEX.md"
---
track: python
guide: G4
dimensions: [D3, D8]
level: P1
status: draft
links: [知识点清单.md, 实践指南.md, 开发指南.md, 问题指南.md, 工具指南.md, FAQ.md, 错误处理指南.md, 排查手册.md, 工程参考.md]
examples: [E-001-exception-hierarchy, E-008-fail-fast-exit, E-015-antipattern-compare, L0-hello]
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-11
---

# Python 轨道索引（INDEX）

> 本文只有一个主要承诺：**反查**。从任何一篇文档、一个 E 系用例或一个 lab 出发，
> 都能在这里找到它属于哪条学习线、下一步去哪。本文不含正文，全部条目外链到对应文件。

## 1. 指南层反查（7 篇既有指南 + 3 篇 M11 新增）

| 文件 | 类型 | 一句话职责 | 什么时候打开 |
|---|---|---|---|
| [知识点清单](知识点清单.md) | 清单 | L1–L4 用例 ID 清单 + E 系反查表（§E） | 「练什么」 |
| [清单自检](清单自检.md) | 自检 | 探针式逐 KP 快速自测 | 怀疑某个 KP 没学会 |
| [实践指南](实践指南.md) | G1 | 知识点放进真实任务：何时用/不用会怎样 | 想把 KP 用起来 |
| [开发指南](开发指南.md) | G2 | 环境到提交的完整动线 | 从零开始动手 |
| [问题指南](问题指南.md) | G3 | 按问题域组织疑难：现象→假设→定位→修复 | 卡在一个具体故障（语言层） |
| [工具指南](工具指南.md) | G4 | 工具清单、调用、参数速查 | 查工具用法 |
| [FAQ](FAQ.md) | G5 | 高频短问答 | 10 秒内想要答案 |
| [错误处理指南](错误处理指南.md) | G1（M11 新增） | 错误处理操作动线：分类→捕获→链→容错→退出→报告 | 写错误处理代码时 |
| [排查手册](排查手册.md) | G3（M11 新增） | E 系 15 节：症状→命令→判据→修复 | 排查错误处理类故障 |
| [工程参考](工程参考.md) | G4（M11 新增） | 镜像/构建/依赖/环境变量/版本真本速查 | 查工程事实 |

## 2. E 系示范用例反查（15 例）

全部位于 `python/examples/`，运行契约 `TAG=latest scripts/run-example.sh python <ID>`；
一行速查版在 [知识点清单 §E](知识点清单.md)，逐例正文在各自 README。

| 用例 | 考点关键词 | 主关联文档 |
|---|---|---|
| [E-001-exception-hierarchy](../examples/E-001-exception-hierarchy/README.md) | 异常层次、类别→动作 | [排查手册](排查手册.md) §2.1 |
| [E-002-except-order](../examples/E-002-except-order/README.md) | except 匹配顺序 | [排查手册](排查手册.md) §2.2 |
| [E-003-exception-chaining](../examples/E-003-exception-chaining/README.md) | 异常链三形态 | [排查手册](排查手册.md) §2.3 |
| [E-004-eafp-lbyl](../examples/E-004-eafp-lbyl/README.md) | EAFP vs LBYL | [排查手册](排查手册.md) §2.4 |
| [E-005-errno-mapping](../examples/E-005-errno-mapping/README.md) | errno/OSError 映射 | [排查手册](排查手册.md) §2.5 |
| [E-006-cleanup-order](../examples/E-006-cleanup-order/README.md) | 清理逆序回滚、suppress | [排查手册](排查手册.md) §2.6 |
| [E-007-retry-backoff](../examples/E-007-retry-backoff/README.md) | 重试分类、指数退避 | [排查手册](排查手册.md) §2.7 |
| [E-008-fail-fast-exit](../examples/E-008-fail-fast-exit/README.md) | 退出码协议、边界即拒 | [排查手册](排查手册.md) §2.8 |
| [E-009-error-aggregation](../examples/E-009-error-aggregation/README.md) | 校验错误聚合 | [排查手册](排查手册.md) §2.9 |
| [E-010-structured-logging](../examples/E-010-structured-logging/README.md) | JSON 结构化日志 | [排查手册](排查手册.md) §2.10 |
| [E-011-timeout-deadline](../examples/E-011-timeout-deadline/README.md) | 截止时间、超时分类 | [排查手册](排查手册.md) §2.11 |
| [E-012-message-contract](../examples/E-012-message-contract/README.md) | 异常消息契约 | [排查手册](排查手册.md) §2.12 |
| [E-013-excepthook-boundary](../examples/E-013-excepthook-boundary/README.md) | 未捕获异常兜底 | [排查手册](排查手册.md) §2.13 |
| [E-014-graceful-degradation](../examples/E-014-graceful-degradation/README.md) | 降级留痕 | [排查手册](排查手册.md) §2.14 |
| [E-015-antipattern-compare](../examples/E-015-antipattern-compare/README.md) | 三大反模式对照 | [排查手册](排查手册.md) §2.15 |

## 3. 轨道 lab 反查（1 个）

| lab | 故障形态 | 入口 | 判读文档 |
|---|---|---|---|
| T-001-venv-mix-mutable-default | venv 混用 × 可变默认值的复合故障 | `python/labs/T-001-venv-mix-mutable-default/run.sh` | [WALKTHROUGH.md](../labs/T-001-venv-mix-mutable-default/WALKTHROUGH.md) |

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
__BDI_EOF_TPL_python__

  cat <<'__BDI_EOF_TPL_java__' > "$DEST/java/docs/INDEX.md"
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
__BDI_EOF_TPL_java__

  cat <<'__BDI_EOF_TPL_vue__' > "$DEST/vue/docs/INDEX.md"
---
track: vue
guide: reference       # Diátaxis reference（轨道索引）；M11-DOC 新增文档类型，不在 docs/11 §1 的 G1..G5 五类之列
dimensions: [D8]
level: P1
status: draft
links: [知识点清单.md, 错误处理指南.md, 排查手册.md, 工程参考.md]
examples: [L0-hello, E-001-error-taxonomy, E-015-antipattern-compare]
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-11
---

# Vue 轨道索引（INDEX）

> 反查表：从「我要的东西」反查到具体文件。覆盖本轨 10 篇指南文档、
> 15 个 E 类示例、1 个 lab 与清单 E 段。全站索引归 `docs/INDEX.md`（本卡不改）。

## 1. 指南文档反查（10 篇）

| 文档 | 类型 | 回答的问题 |
|---|---|---|
| [知识点清单](知识点清单.md) | 清单 | 练什么：L0/L1/L2/L3 用例 ID 清单 + E 段反查表 |
| [实践指南](实践指南.md) | G1 how-to | 什么时候用、不用会怎样、怎么验 |
| [开发指南](开发指南.md) | G2 how-to | 从零到能改：环境、目录、构建、提交动线 |
| [问题指南](问题指南.md) | G3 troubleshooting | 按问题域的疑难：现象 → 假设 → 定位 → 修复 |
| [工具指南](工具指南.md) | G4 reference | 编译/SFC/SSR 工具速查与误用 |
| [FAQ](FAQ.md) | G5 reference | 高频短问答 |
| [用例编写规范](用例编写规范.md) | 规范 | 新用例怎么写才算合格 |
| [错误处理指南](错误处理指南.md) | how-to（M11-DOC 新增） | 要把错误处理写对：任务 → 动作 → E 例 → 验证命令 |
| [排查手册](排查手册.md) | troubleshooting（M11-DOC 新增） | 坏了怎么查：症状 → 命令 → 判据 → 修复（§2 逐节对应 E-001..E-015） |
| [工程参考](工程参考.md) | reference（M11-DOC 新增） | 镜像层/版本真本/命令/环境变量/计数口径查表 |

## 2. E 类示例反查（15 个，`vue/examples/E-0xx-*`）

详细判读统一走 [排查手册](排查手册.md) §2 对应节；本表只做 ID → 考点反查。

| 用例 | 一句话考点 | 排查手册节 |
|---|---|---|
| [E-001-error-taxonomy](../examples/E-001-error-taxonomy/README.md) | 错误来源分类（info 位置类别） | §2.1 |
| [E-002-error-create](../examples/E-002-error-create/README.md) | 错误对象构造（code/field/message） | §2.2 |
| [E-003-error-match](../examples/E-003-error-match/README.md) | 错误匹配与分派（不解析文案） | §2.3 |
| [E-004-error-wrap](../examples/E-004-error-wrap/README.md) | 传播与包装（context + cause） | §2.4 |
| [E-005-error-identity](../examples/E-005-error-identity/README.md) | 错误身份保持（透传同一引用） | §2.5 |
| [E-006-error-context](../examples/E-006-error-context/README.md) | 错误上下文标注（组件链） | §2.6 |
| [E-007-cleanup-guarantee](../examples/E-007-cleanup-guarantee/README.md) | 副作用清理保证 | §2.7 |
| [E-008-error-reraise](../examples/E-008-error-reraise/README.md) | 不吞错与重抛（return false 纪律） | §2.8 |
| [E-009-async-boundary](../examples/E-009-async-boundary/README.md) | 异步边界能力范围 | §2.9 |
| [E-010-retry-backoff](../examples/E-010-retry-backoff/README.md) | 重试与退避 | §2.10 |
| [E-011-timeout-deadline](../examples/E-011-timeout-deadline/README.md) | 截止时间（Promise.race） | §2.11 |
| [E-012-error-aggregate](../examples/E-012-error-aggregate/README.md) | 并行失败聚合（allSettled） | §2.12 |
| [E-013-error-observability](../examples/E-013-error-observability/README.md) | 可观测性（唯一汇聚点 + 三元组） | §2.13 |
| [E-014-fail-fast](../examples/E-014-fail-fast/README.md) | 配置 fail-fast（createApp 之前） | §2.14 |
| [E-015-antipattern-compare](../examples/E-015-antipattern-compare/README.md) | 反模式对照（三大假绿） | §2.15 |

清单侧反查表见 [知识点清单](知识点清单.md) `## E` 段（逐行含排查命令与判据）。

## 3. lab 反查（1 个）

| lab | 场景 | 判读文档 |
|---|---|---|
| [T-001-props-reactivity-env](../labs/T-001-props-reactivity-env/WALKTHROUGH.md) | Vue 解构 props 丢响应性 + 生产环境变量内联：运行时挂载观测 / effect 隔离 / 产物静态分析交叉验证 | `vue/labs/T-001-props-reactivity-env/WALKTHROUGH.md` |

## 4. 「我要查 X」反查示例

- 我要练某个语法点 → [知识点清单](知识点清单.md) L1/L2/L3 段按 ID 查。
- 我要把错误处理写对 → [错误处理指南](错误处理指南.md) §2 任务路由表。
- 我手上有个故障 → [排查手册](排查手册.md)按症状找节；响应性/构建类走 §3 路由。
- 我要查镜像/版本/环境变量 → [工程参考](工程参考.md) §2、§4。
- 我要跑某个用例 → `TAG=latest scripts/run-example.sh vue <ID>`（契约见
  [工程参考](工程参考.md) §3）。
- 我要做一个排障演练 → [T-001 WALKTHROUGH](../labs/T-001-props-reactivity-env/WALKTHROUGH.md)，
  规范见 [docs/72](../../docs/72-排障演练规范.md)。
- 我有小疑问 → [FAQ](FAQ.md)；查不到的入口在各篇「相关」节与
  [docs/ROADMAP](../../docs/ROADMAP.md) KI 段。
__BDI_EOF_TPL_vue__

  cat <<'__BDI_EOF_TPL_db__' > "$DEST/db/docs/INDEX.md"
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
__BDI_EOF_TPL_db__

  if [ "$CHECK" = 1 ]; then
    local rc=0 rel
    for rel in docs/INDEX.md docs/INDEX-by-example.md \
               c/docs/INDEX.md cpp/docs/INDEX.md go/docs/INDEX.md rust/docs/INDEX.md \
               shell/docs/INDEX.md python/docs/INDEX.md java/docs/INDEX.md vue/docs/INDEX.md \
               db/docs/INDEX.md; do
      if ! cmp -s "$ROOT/$rel" "$DEST/$rel"; then
        echo "DRIFT: $rel 与仓库实况不一致（运行 bash scripts/build-doc-index.sh 重生成）"
        diff -u "$ROOT/$rel" "$DEST/$rel" | sed -n '2,12p' || true
        rc=1
      fi
    done
    if [ "$rc" = 0 ]; then echo "OK: 三层索引（11 个文件）与仓库实况一致"; fi
    return "$rc"
  fi
  echo "OK: 已重生成 11 个索引文件（docs/INDEX.md、9 轨 docs/INDEX.md、docs/INDEX-by-example.md）"
}

main
