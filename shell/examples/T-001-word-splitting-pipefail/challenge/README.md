# T-001-word-splitting-pipefail · faded 挑战档

> 规则（docs/72 §4.3）：这里只给触发症状与可用工具清单，不给判读。
> 请先自己按 WALKTHROUGH 的 §4.1 结构（触发症状 / 前 60 秒三条只读检查 / 互斥决策树 /
> 逐行判读 / 改动后验证）写一遍，再对照 [SOLUTION.md](SOLUTION.md)。

## 触发症状

同事报障：一个巡检脚本「每天跑、退出码永远 0、告警从没触发过」，但下游确认
某台机器的部署日志从来没被统计进来。你在 devbox-shell 容器内复现（脚本已缩小）：

```bash
bash bug.sh; echo "rc=$?"
```

输出里有几个「看起来合理」的数字，一个报错，退出码 1。review 的人说：
「rc=1 会触发告警，问题不大」——但 rc=1 与报错行说的事，和 rc=0 那一行
说的事，根本不是同一个缺陷。

## 你的任务

1. 先排除「脚本没被真正执行 / 环境探测失败被误读为代码问题」（素材 S-06 的分支）；
2. 把「退出码 0 的假成功」与「文件名被拆开」分别钉到 bug.sh 的具体行，
   并回答：rc=1 能不能兜住 rc=0 那个缺陷？为什么？
3. 给出修复 diff 与修复后的验证证据（失败要可见、数字要对、静态检查要过；
   注意修复时有个「顺手删 2>/dev/null」的讲究，想清楚为什么）。

## 可用工具清单（均在 devbox-shell 镜像内，宿主上没有）

- shellcheck 0.9（静态分析；注意 severity 档位与仓库门禁 `-S warning` 的关系）
- bash 5.2（`bash -x` 追踪展开；`bash -o pipefail -c` 做管道退出码对照实验）
- `false | true` 一分钟对照实验（自己搭）
- 同目录 `repro.sh` / `run.sh` / `assert.sh` 可作对照（先别看 WALKTHROUGH）

## 提交判据

`bash assert.sh` 输出 ASSERT-PASS；你的判读文档里至少有 1 个 predict–observe–explain
点与 2 条被否决的假设。
