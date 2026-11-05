# SOLUTION · T-001-word-splitting-pipefail（faded 挑战档答案）

> 仅供自查，**不进 CI 断言**（docs/72 §4.3）。先自己写完判读再回来对。
> 以下输出均为 2026-11-06 devbox-shell 容器真跑（路径已归一化）。

## 1. 先证脚本真的被执行过，再谈代码

标记行 `split: start` 打印了 → 脚本真的跑过 → 可以谈代码（素材 S-06）。

predict–observe–explain：预测「grep 目标文件不存在，脚本会报错」→ 观察
`pipeline: matched=0 rc=0` → 解释：管道退出码取最后一段，wc 的 0 把 grep 的 2
整个吞掉，加上 `2>/dev/null` 删掉报错，两个通道同时无痕迹。rc=0 的「全绿」
在这里不是安全的信号，而是缺陷本体的形态（素材 S-07）。

## 2. 两个缺陷分别钉在哪；rc=1 能不能兜住 rc=0 那个缺陷

**缺陷 A：管道吞错（bug.sh:16）**——`grep ... | wc -l` 无 pipefail：

```text
pipeline: matched=0 rc=0        ← rc 取 wc 的 0，grep 的 2 被丢弃
```

对照实验：`bash -c "false | true"` → rc=0；`bash -o pipefail -c ...` → rc=1。
真实管道加 pipefail 后 → rc=2（grep「文件不存在」）。

**缺陷 B：分词（bug.sh:25/27）**——`wc -l $target`，`$target` 含空格：

```text
split: lines=[0 total]                                        ← 2>/dev/null 删报错后剩貌似合理的数字
wc: /TMP/.../report: No such file or directory                ← 路径断尾
wc: final.txt: No such file or directory                      ← 分词产物，无目录前缀
+ wc -l /TMP/.../report final.txt                             ← bash -x：一个变量，两个参数
```

shellcheck 默认 severity：`bug.sh:25:15` 与 `bug.sh:27:7` 两处 SC2086。
注意 SC2086 是 info 级，仓库门禁 `-S warning` 看不见（实测退出 0）——
静态检查要选对档位。

**rc=1 兜不住 rc=0 那个缺陷。** rc=1 只来自最后一条 wc（分词缺陷 B 的漏出），
而缺陷 A 的现场 `matched=0 rc=0` 早已把「无匹配」的假结论写进输出流——两个
缺陷互相独立，一个的退出码挡不住另一个的假成功。

## 3. 被否决的假设（自查：你至少写了两条吗）

- H1 真的无匹配？→ 文件应存在、grep rc=1；实际文件不存在 rc=2 且 stderr 被删
  → 否（双重掩盖）。
- H2 丢了 final.txt？→ `bash -x` 显示 wc 收到 2 个参数，final.txt 是分词产物
  → 否。
- H3 set -e 能防吞错？→ 实测 `bash -e -c "false | true; echo survived=$?"`
  打出 survived=0 → 否，防吞错必须 pipefail，set -e 是互补不是替代。
- H4 修复只要加 pipefail 就够？→ 不够：分词还在，且 `2>/dev/null` 会继续删
  报错——三处一起改（pipefail + 引号 + 删 2>/dev/null），失败可见与数字正确
  两个判据才同时绿。

## 4. 修复 diff 与验证

```diff
 #!/usr/bin/env bash
+set -uo pipefail
...
-lines=$(wc -l $target 2>/dev/null)
+lines=$(wc -l "$target")
...
-wc -l $target
+wc -l "$target"
```

验证（2026-11-06 修复版真跑）：

```text
pipeline: matched=0 rc=2                ← pipefail 顶出 grep 失败（对照 rc=0）
split: lines=[3 /TMP/.../report final.txt]   ← 数字正确（对照 0 total）
rc=0                                    ← 无 No such file；shellcheck 复查 SC2086 消失
```

两个维度都绿才算修好：失败可见（rc=2）+ 数字正确（3 行）；把改动落到 lab 的
bug.sh 前先想清楚——那是缺陷现场，assert.sh 按设计断言「故障在场」，修了它
lab 就废了。
