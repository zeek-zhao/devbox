# E-008-error-reraise —— 记录后重抛：记录不能替代失败

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-008 记录后重抛），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

「处理」失败最常见的假动作：函数捕获失败、往日志里写一句
"step failed rc=4"、然后 `return 0`。日志里明明有记录，上层却拿到成功——
监控说一切正常，业务其实没有发生。记录和处理被混为一谈。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-008-error-reraise
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-008-error-reraise \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：两种模式都写出了同一条报告
（`report=step failed rc=4`），但 swallow 模式 exit=0、reraise 模式 exit=4。

## 为什么这样处理

- 记录与传播分开：`REPORT` 变量负责记录（进入日志/上报），
  `return "$rc"` 负责把失败原码上抛——两条通道都要走，缺一不可。
- 只有「这一层真的处理掉了失败」（比如降级到默认值）才允许 return 0；
  仅仅「看见」失败不构成处理，码必须继续上抛。
- 对照行并排输出：同一个失败、同一份记录，exit=0 与 exit=4 的差别
  就是「假装处理过」与「真正传播」的差别。

## 反例

- `cmd || { log "failed"; return 0; }`：把日志当处理，失败被吞成成功。
- 重抛时换码：`return 1`，上层按码分派的逻辑（E-003）命不中。
- 只上抛不记录：上层拿到了失败，但本地现场（在哪一步、什么原因）丢了。
