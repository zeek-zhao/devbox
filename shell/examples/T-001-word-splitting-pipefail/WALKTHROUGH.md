---
title: WALKTHROUGH · T-001-word-splitting-pipefail（Shell 分词与管道吞错排查）
track: shell
lab: T-001-word-splitting-pipefail
难度: P2          # P0–P5 刻度：双缺陷、需跨 shellcheck / bash -x / pipefail 对照多工具交叉验证
status: draft
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-06
素材: 类型②实验（复现命令见 §1）+ 素材 S-07（CI 全绿 ≠ 教学质量达标）+ 素材 S-06（执行标记行纪律）
verified_env: devbox-shell:latest（bash 5.2.21 / shellcheck 0.9.0）
---

# WALKTHROUGH · T-001-word-splitting-pipefail

> 依据 [docs/72 排障演练规范](../../../../docs/72-排障演练规范.md) §4 编写；D1 拍板见
> [docs/73 §11](../../../../docs/73-M11并发执行计划.md)。所有输出均为 2026-11-06 在
> devbox-shell 容器内真跑所得（临时目录路径已按规范归一化为 `/TMP`，无内网信息）。
>
> 与样板 cpp/examples/T-001-asan-heap-overflow 的差异点：Shell 轨道的「缺陷现场」是
> 可执行标本 `bug.sh`（对应 cpp 的 main.cpp）；工具组合是 shellcheck（静态）+
> bash 运行时行为（`-x` 追踪 / pipefail 开关对照），没有 valgrind/gdb 对应物。
> 另有一个 severity 知识点：SC2086 在 shellcheck 0.9 里是 info 级，仓库门禁的
> `-S warning` 档看不见它（§4.1），所以 run.sh 用默认 severity 显式打出。

## 1. 触发症状

在 devbox-shell 容器内直跑缺陷脚本：

```bash
bash bug.sh; echo "rc=$?"
```

真实输出（类型②实验，2026-11-06；路径已归一化）：

```text
split: start
pipeline: matched=0 rc=0
pipeline: 判定为无匹配（真相：左侧 grep 因文件不存在整体失败，被 wc 吞掉）
split: 想统计这个文件的行数 [/TMP/devbox-shell-T-001-fixture/report final.txt]
split: lines=[0 total]
wc: /TMP/devbox-shell-T-001-fixture/report: No such file or directory
wc: final.txt: No such file or directory
0 total
rc=1
```

**症状一：脚本「成功」，结论却是假的。** `bug.sh:16` 的管道里，grep 因目标文件
不存在整体失败（rc=2），wc 成功（rc=0）——没有 `set -o pipefail` 时管道退出码取
最后一段，`matched=0 rc=0` 把「日志文件根本没被读到」洗成了「无匹配」。调度器、
CI、上层脚本看到的都是 rc=0 全绿（来源：S-07）。

**症状二：含空格的文件名被拆成两个参数。** `bug.sh:25/27` 的 `wc -l $target`，
`$target` 值为 `…/report final.txt`，展开后按空白分词：wc 收到 `…/report` 和
`final.txt` 两个都不存在的参数。报错两行就是分词指纹——第一行路径缺了尾巴
（`.../report`），第二行 `final.txt` 连目录前缀都没有。

**症状三：拿到一个貌似合理的错误数字。** `split: lines=[0 total]`——`2>/dev/null`
把报错删掉后，stdout 里剩下 wc 对空输入的 `0 total`。脚本继续拿着这个数字往下走，
无人报错、无栈可看。

## 2. 前 60 秒三条只读检查（成本从低到高，均不改任何状态）

| # | 命令 | 健康时看到 | 异常时看到 |
|---|---|---|---|
| 1 | 重跑一次并看标记行与 `echo $?` | `split: start` 打印、退出码符合预期 | **无 `split: start`** → 脚本可能根本没被执行（素材 S-06：先排除环境，再谈代码）；`No such file or directory` + rc=1 → 分词现场 |
| 2 | `bash --version \| head -1; shellcheck --version \| head -2` | `GNU bash, version 5.2.21...` / `version: 0.9.0` | `command not found` → 镜像/环境问题，不是代码问题；停，交维护者 |
| 3 | `bash repro.sh 2>&1 \| grep -E "matched=\|No such"` | 异常现场：`pipeline: matched=0 rc=0` + 两行 `No such file or directory` | 只有标记行、无诊断行且 rc=0 → 故障未被触发，走 §3 决策树 Q3 右枝 |

三条都只读：不改代码、不改构建、不装东西。

## 3. 互斥决策树（每叉二选一，无死分支、无循环）

```text
Q0 重跑缺陷脚本，标记行 split: start 打印了吗？
├─ 没打印 → 素材 S-06 分支：先确认脚本真的被执行过——
│     bash -n bug.sh                （语法先过？）
│     ls -l bug.sh && pwd           （跑的是不是同目录这个文件？）
│     → 修环境/调用方式，不是修代码
└─ 打印了 → Q1 症状是哪一类？
    ├─ 报错行 No such file or directory，且文件名被截断/缺目录前缀
    │     → 分词缺陷（bug.sh:25/27）→ Q2
    ├─ 退出码 0 但结果可疑（计数 0 / 报表空 / 日志像没读过）
    │     → 吞错缺陷（bug.sh:16）→ Q3
    └─ 其他（Permission denied / syntax error / command not found）
          → 与本 lab 现场不符，停止并登记 UNVERIFIED 交维护者

Q2 分词验证：bash -x 看案发命令实际收到几个参数（run.sh step 4 的做法）
├─ 参数数 > 1 → 分词坐实 → 修复：给变量展开加引号（"$target"）→ §6
└─ 参数数 = 1 → 分词不是本案：查 glob 展开或 IFS 被改 → 与本现场不符，
      登记 UNVERIFIED
Q3 吞错验证：对照实验（run.sh step 2/5 的做法）
├─ bash -c "false | true" → 0 且 bash -o pipefail -c ... → 1
│     → 吞错坐实 → 修复：脚本头部 set -o pipefail → §6
└─ 两条都是 1 → 当前 shell 环境已全局开了 pipefail（复现环境被污染），
      换干净 shell（env -i bash --noprofile --norc）重验
```

## 4. 逐行判读（真实输出，2026-11-06 devbox-shell 容器真跑）

### 4.1 shellcheck（静态分析器，默认 severity）

```text
bug.sh:16:9: note: Consider using 'grep -c' instead of 'grep|wc -l'. [SC2126]
bug.sh:25:15: note: Double quote to prevent globbing and word splitting. [SC2086]
bug.sh:27:7: note: Double quote to prevent globbing and word splitting. [SC2086]
```

- `bug.sh:25` 与 `bug.sh:27`：两处 `$target` 展开点（`$(wc -l $target ...)` 和
  结尾的 `wc -l $target`），shellcheck 直接给出修法 `wc -l "$target"`；
  assert.sh 锚的就是 `SC2086` 这个串；
- `bug.sh:16` 的 SC2126（`grep|wc -l` 建议直接 `grep -c`）是顺手捡到的次生问题，
  修复时一并处理；
- **severity 知识点**：SC2086 在 shellcheck 0.9.0 里是 info 级。实测
  `shellcheck -S warning bug.sh` 退出 0、零输出——仓库静态门禁的 `-S warning`
  档看不见它。门禁的 severity 阈值决定它能看见什么，**门禁绿 ≠ 无此类缺陷**
  （来源：S-07）。

### 4.2 直跑输出逐行（§1 的输出块）

- `pipeline: matched=0 rc=0`：`$?` 取的是管道最后一段 wc 的退出码。grep rc=2
  被丢弃——这是「管道吞错」的定义性现场；
- `split: lines=[0 total]`：wc 对两个不存在参数输出错误到 stderr（被
  `2>/dev/null` 删掉），stdout 留下 `0 total`。**报错被删、留下貌似合理的数字**
  是吞错的加强版：管道没吞它，是我们自己 `2>/dev/null` 吞的。两类掩盖手段
  （pipefail 缺失 + stderr 重定向）经常成对出现；
- `wc: /TMP/.../report: No such file or directory`：路径在空格处断尾；
- `wc: final.txt: No such file or directory`：无目录前缀——它是分词产物，
  不是真实文件名（§5 假设 H2）；
- `0 total` + `rc=1`：脚本退出码只反映最后一条 wc 失败，与吞错缺陷无关——
  两个缺陷**互相独立**（§5 H3）。

### 4.3 bash -x 追踪（亲眼看分词）

```text
+ wc -l /TMP/devbox-shell-T-001-fixture/report final.txt
```

源代码里是**一个**变量 `$target`，`-x` 展开后 wc 收到 **2 个参数**。分词不是玄学：
bash 对未加引号的展开按 IFS（默认空白）切分，`-x` 追踪里白纸黑字。

### 4.4 对照实验与 pipefail 语义

```text
对照实验: false|true → rc=0（plain：右侧成功掩盖左侧失败）
对照实验: pipefail 开启 → rc=1（管道取最右侧非零退出码）
pipefail 对照: 同一条管道 plain → rc=0（吞掉）
pipefail 对照: pipefail → rc=2（左侧 grep 因文件不存在 rc=2）
```

`set -o pipefail` 的语义：管道退出码 = **最右侧的非零退出码**（全零才取 0）。
真实管道的 rc=2 正是 grep「文件不存在」的退出码——pipefail 让失败从管道里
冒出来，而不是被统计步骤洗白。

## 5. 认知学徒双层（docs/72 §4.2 拍板项）

### 5.1 predict–observe–explain（POE 点）

先书面写下你的预测再跑：

> **预测**：grep 的目标文件根本不存在，这段管道所在的脚本会报错退出吗？
> 退出码是多少？（多数人预测：报错 / 非零退出。）

**观察**（真实输出）：

```text
pipeline: matched=0 rc=0
```

**explain 落差**：管道退出码取**最后一段**——wc 对空输入正常返回 0，左侧 grep
的失败被整个丢弃。更糟的是 `2>/dev/null` 把 grep 的报错也删了，于是「文件没读到」
在输出和退出码两个通道上都无痕迹，只剩一个看似合理的 `matched=0`。这就是
「CI 全绿但线上数据是错的」的经典 Shell 成因（来源：S-07）。

### 5.2 被否决的假设（≥2 条，含排除过程）

| # | 假设 | 若为真应看到 | 实际看到 | 结论 |
|---|---|---|---|---|
| H1 | `matched=0` 是真的无匹配（日志里有但格式不对） | 目标文件存在、grep 退出码 1（「没匹配到」） | 文件根本不存在、grep rc=2，且 stderr 被 `2>/dev/null` 删除 | 排除：错误被**双重掩盖**（pipefail 缺失 + stderr 重定向） |
| H2 | 有个叫 `final.txt` 的文件丢了 | `ls final.txt` 能找到、或路径里真有这个文件 | `final.txt` 是 `$target` 在空格处被切开的**分词产物**，cwd 下不存在；`-x` 追踪显示 wc 收到 2 个参数 | 排除：文件从来没丢，是一个变量被读成了两个 |
| H3 | 脚本 rc=1，说明错误没被吞、监控能发现 | CI/调度器对 rc=1 报警，吞错缺陷会被连带暴露 | rc=1 只来自最后一条 wc（分词缺陷）；吞错现场 `matched=0 rc=0` 早已把错误结论写进输出流 | 排除：两个缺陷独立，rc=1 挡不住 rc=0 的假结论往前走 |
| H4 | `set -e` 能防住吞错 | 加 `set -e` 后脚本在管道处退出 | 实测 `bash -e -c "false \| true; echo survived=$?"` 打出 `survived=0`——`-e` 对管道同样只看最后一段，rc=0 不触发 | 排除：防吞错必须 `set -o pipefail`；`set -e` 与 pipefail 是互补而非替代 |

## 6. 改动后验证

修复 = 两处独立改动（在**副本**上做，别动 lab 自身的缺陷现场，否则断言全红）：

```bash
cd shell/examples/T-001-word-splitting-pipefail
cp bug.sh /tmp/fixed.sh
```

手工改 /tmp/fixed.sh：

```diff
 #!/usr/bin/env bash
+# 缺陷 2 修复：pipefail 让管道失败再也藏不住
+set -uo pipefail
...
-lines=$(wc -l $target 2>/dev/null)     # 缺陷 1：$target 不加引号 → 分词
+lines=$(wc -l "$target")               # 缺陷 1 修复：加引号（同时去掉 2>/dev/null，别删报错）
...
-wc -l $target
+wc -l "$target"
```

健康对照（2026-11-06 修复版真跑）：

```text
split: start
pipeline: matched=0 rc=2
split: 想统计这个文件的行数 [/TMP/devbox-shell-T-001-fixture/report final.txt]
split: lines=[3 /TMP/devbox-shell-T-001-fixture/report final.txt]
3 /TMP/devbox-shell-T-001-fixture/report final.txt
rc=0
```

两个维度都绿 = 修好：`rc=2` 说明 pipefail 把 grep 的失败**顶了出来**（对照 §4.2
的 `rc=0`——同一个失败从「吞掉」变成「可见」）；`lines=[3 …]` 是正确的行数
（对照 `0 total`），且 `No such file or directory` 消失。shellcheck 复查修复版：
SC2086 全部消失，只剩 SC2126（style 级，建议改用 `grep -c`，可顺手改）。
注意健康判据不是「rc=0」本身——是**失败可见 + 数字正确**两件事同时成立。

## 7. 停止 / 升级条件（docs/71 §5 stop rules 对齐）

碰到任一条，停下来交维护者，不自行发挥：

1. `bash` / `shellcheck` 任一 `command not found`（镜像缺工具，环境问题）；
2. 同一验证命令**连续两次失败**（含 assert.sh 连红两次）；
3. 对照实验结果与本 lab 现场不符（如 plain 下 `false | true` 竟 rc=1，提示
   环境被全局 pipefail 污染，复现不干净）；
4. 需要修改 `shell/examples/T-001-word-splitting-pipefail/` 目录之外的文件才能继续；
5. 验收判据有歧义。

## 8. last verified 与 UNVERIFIED 表

**last verified: 2026-11-06**，devbox-shell:latest 容器（bash 5.2.21 / shellcheck
0.9.0，Docker on Linux）。`run.sh` 连跑 3 次（含 assert.sh 内两次）均 RUN-PASS
5/5、退出码 0；`assert.sh` 连跑 2 次均 ASSERT-PASS、退出码 0，结论一致；
`shellcheck -S warning shell/examples/T-001-*/*.sh` 退出 0。

| 判据 | 状态 | 原因 | 谁来补验 |
|---|---|---|---|
| IFS 被显式改动（如 `IFS=:`）时的分词行为差异 | UNVERIFIED | 本 lab 只覆盖默认 IFS（空白分词） | 做分词进阶变体 lab 时补 |
| zsh / dash 等非 bash shell 的行为差异 | UNVERIFIED | 本镜像只实测 bash 5.2.21；pipefail 语义在各 shell 间有出入 | 维护者扩镜像时复跑 |
| SC2086 severity 在未来 shellcheck 版本中的变化（0.9.0 为 info） | UNVERIFIED | 门禁 `-S warning` 是否继续放过缺陷标本取决于上游分级 | 升级 devbox-shell 镜像时复跑 §4.1 两条命令 |
| `set -Eo pipefail` + `trap ERR` 的报错捕获形态 | UNVERIFIED | 本 lab 只验证 pipefail 开关本体 | 做防御性编程变体 lab 时补 |
| challenge/ 档的学习者实测用时与卡点 | UNVERIFIED | faded 档按定义不给判读，无真人试做记录 | 首位完成 challenge 的学习者回填 |

## 9. 素材来源

- **类型②实验**：§1/§4 全部现象均为 2026-11-06 在 devbox-shell 容器内真跑所得，
  复现命令即 §1 与 `repro.sh`；输出已按 docs/72 §2 归一化（临时目录 → `/TMP`），
  不含内网信息。
- **来源：S-07**（docs/24-G3素材池.md）：「CI 全绿 ≠ 教学质量达标」——§1 症状一
  （rc=0 掩盖 grep 失败）、§4.1（`-S warning` 门禁看不见 info 级 SC2086）与
  §5.1 POE 点（退出码 0 ≠ 没有错误）都是该素材的应用。
- **来源：S-06**（docs/24-G3素材池.md）：「镜像探测失败被误读为代码问题」——
  §2 检查 1 与 §3 Q0 分支（标记行缺失 → 先证脚本真的被执行过）遵循该素材纪律。
