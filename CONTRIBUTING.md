# 贡献指南

这个仓库是教学型项目：每个用例都是一段**可运行、可验证**的最小示例。所以贡献的
门槛不在「写多少代码」，而在「能不能被 runner 逐字验证」。

## 最快的上手路径

```bash
git clone https://github.com/zeek-zhao/devbox.git
cd devbox

# 用已发布镜像跑一门轨道（不需要本地构建镜像）
make examples LANG=cpp TAG=latest

# 只想跑一个用例
bash scripts/run-example.sh cpp L1-001-string-view
```

## 用例契约（硬约束）

每个用例目录**恰好**三个文件：

```text
cpp/examples/L1-001-string-view/
├── run.sh          # 可执行；set -euo pipefail；业务结果写 stdout
├── expected.txt    # 期望输出，逐行比对
└── README.md       # 考点、判据、边界
```

- runner 把 `run.sh` 的 stdout 与 `expected.txt` **逐行比较**；行尾空白与首尾空行忽略，
  其余必须一致。
- **输出必须确定**：集合显式排序，浮点数固定精度，不要打印时间戳、随机数、内存地址、
  容器 IP、耗时。同一条用例连跑两次必须完全一致。
- 错误信息写 **stderr**，业务结果写 **stdout**——写反了会让失败日志只剩 compose 输出。
- 用例 ID 形如 `L<层级>-<序号>-<slug>`，`L1`–`L4` 表示难度层级。
- 不要改 `.gitattributes` 的 `eol=lf`。Windows 上开发、Linux 容器里执行，CRLF 会让
  `bash run.sh` 报 `No such file or directory`。

## 怎么写一张能被 AI 执行的卡

M11 起任务卡走 **spec v2**：卡由 `.github/ISSUE_TEMPLATE/agent_task.yml` 表单创建，执行 AI 按卡干活、独立 verifier 判卷。完整规范见 [docs/71-任务卡规范v2](docs/71-任务卡规范v2.md)，派单与批次见 [docs/73-M11并发执行计划](docs/73-M11并发执行计划.md)。

九栏逐栏含义（与表单一一对应）：

| 栏 | 填什么 |
|---|---|
| 目标与背景 | 为什么要做这张卡（一句话 + 依据链接） |
| 验收判据 | 每条**可判定**：给得出命令或机械计数，不写「写清楚、效果好」 |
| 独占文件 | 本卡允许改动的全部文件（并发安全的关键） |
| 明确不做 | 边界外的事逐条列，防自动化自行发挥 |
| 验证命令与期望输出 | 判据对应的可执行命令 |
| 执行留痕 | run_id / files_changed / commands_run / tests_passed / risk_notes / review_needed 六字段 |
| 停止规则 | 碰门禁、凭证、范围外、连续两次验证失败 → 停并问人 |
| 失败与升级路径 | 卡住时去哪、谁接 |
| 依赖与独立性测试 | 硬前置卡；独立性 = A 卡无需知道 B 卡结论即可完成 |

**三条硬规矩**：

1. **REST API / `gh` 建卡会跳过表单**——正文必须按表单的 `###` 标题镜像构造，否则机器解析不到；
2. label 无法经 API 随卡带上时须**显式补传**；
3. `scripts/gate-files.txt` 命中的门禁文件，执行 AI 一律不改（人工批次例外，需 PR 写明理由）。

最小可复制示例（正文骨架，其余照表单栏目展开）：

```markdown
### 验收判据

- [ ] 新建 docs/NN-xxx.md，frontmatter 七字段齐
- [ ] `grep -c "明确不做" docs/NN-xxx.md` 输出 ≥ 1

### 独占文件 / 工作区

- docs/NN-xxx.md（唯一改动者）

### 明确不做

- 不改门禁文件与共享状态文档
- 不代拍 decision / needs-human 事项

### 停止规则

同一验证命令连续两次失败 → 停止并升级维护者。
```

## 提交规范

标题用 Conventional Commits：

```text
<type>(<scope>): <做了什么>

<body：为什么这么改，而不是改了什么——diff 已经说明改了什么>
```

`type` 取 `feat` / `fix` / `docs` / `chore` / `ci` / `refactor` / `test`。
标题写成 `update`、`fix`、`wip` 会被钩子拒绝。

### 提交身份

本仓库 `main` 的历史要求**身份唯一**：`zeek.zhao <zeek.zhao@foxmail.com>`。
两个原因——`git blame` 要能追到人；历史里混进 AI 署名或机器邮箱后，责任边界就模糊了。

- 本地钩子 `.githooks/commit-msg` 会拒绝 `Co-authored-by: <AI>` 一类署名尾巴。
- CI 的 `authors` job 会扫描提交范围：`push main` 与打 tag 时**硬失败**，
  外部 PR 只告警。
- 如果你是从 fork 提交的外部贡献者：**保留你自己的身份**，不用改成维护者邮箱。
  合并时维护者按你的署名保留（或在你同意后 squash）。上面那条唯一性约束只针对
  `main` 上的历史。

启用钩子（克隆后做一次）：

```bash
git config core.hooksPath .githooks
```

## 门禁文件

有些文件定义的是「什么算通过」，而不是「通过什么」。它们包括：CI workflow、
runner、覆盖/预算检查脚本、版本真本、格式化配置、镜像安装脚本。清单见
[`scripts/gate-files.txt`](scripts/gate-files.txt)。

改动这些文件**必须单独一个 PR**，并在描述里写清「为什么旧的判定是错的」。
把判定标准和被测对象放在同一个 PR 里，等于自己给自己发合格证。

## 本地校验（提交 PR 前请跑）

```bash
# 单条用例
bash scripts/run-example.sh <轨道> <用例ID>

# 整门轨道
make examples LANG=<轨道> TAG=latest

# 格式化（只查你改的那门语言）
bash scripts/fmt.sh --check --lang <轨道>

# 覆盖表自洽
bash scripts/coverage-check.sh <轨道>

# 全量总闸（合并前由维护者跑，约 15 分钟）
bash scripts/pre-merge.sh --base main
```

## PR 流程

1. 从 `main` 开分支：`feat/<短描述>` 或 `fix/<短描述>`
2. 只改与标题相关的文件；顺手重构请另开 PR
3. 描述里写：动机、验证方式（贴关键命令与输出）、影响范围
4. CI 会跑全量用例 + 8 门格式 + 覆盖 + 镜像构建，约 20–25 分钟，请耐心等
5. 合并用 **squash**，保持 `main` 一个改动一个提交

## 报告问题

- 功能缺陷 / 用例不确定性 → [新建 Issue](https://github.com/zeek-zhao/devbox/issues/new/choose)
- 安全问题 → **不要开公开 Issue**，见 [SECURITY.md](SECURITY.md)
- 行为准则 → 见 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
