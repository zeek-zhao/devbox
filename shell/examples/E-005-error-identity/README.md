# E-005-error-identity —— 错误身份：同一失败逐层不变

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-005 错误身份），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

一次失败穿过多层函数后，上层看到的是另一件事：有的层把 7 换成 1，
有的层 `|| return 0` 吞成 0，诊断文本也被改写。调用方按身份匹配的
处理分支（E-003）从此永远命不中，排障时对不上现场。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-005-error-identity
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-005-error-identity \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：inner/middle/entry 三层观察到的
`code=7 message=missing-config` 完全一致（身份保持）；
swallowed 层码变 0（身份被销毁），结论行分别给出两种结果。

## 为什么这样处理

- 中间层的唯一职责是透传：`layer_inner || rc=$?` 接住后 `return "$rc"`，
  stderr 不重定向不重写——码与文本在每一层的观察结果逐字一致。
- 用 `observe` 在每一层「当场验身」：身份不是靠相信，是靠逐层比对断言的。
- 吞错层作为对照：`|| return 0` 一行就足够把身份从 7 改成 0，
  上层按 7 建立的全部处理逻辑静默失效。

## 反例

- 中间层顺手 `|| true`：错误从这里「消失」，下游以为无事发生。
- 中间层换码：把 7 改写成 1，错误类别信息在传递中被污染。
- 中间层重写诊断：消息文本每层都变，日志里对不上同一次失败。
