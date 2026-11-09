# E-001-error-taxonomy —— 退出码分类体系

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-001 退出码分类体系），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

同一类失败（比如「输入没给」）在不同调用点行为不一致：有的被当成调用方 bug 直接退出，
有的被当成外部环境问题重试三次。根因是失败只以一个裸的非零码往上传，
脚本里没有统一的「码 -> 类别」体系，每个调用点各自解读。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-001-error-taxonomy
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-001-error-taxonomy \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：5 个退出码各归入唯一类别，末行是分类汇总
（`usage=1 environment=2 internal=1`）。

## 为什么这样处理

- 退出码用一组常量集中定义，`classify()` 对每个码给出唯一归类——同一个码在任何
  调用点解读一致，分类体系不会随调用点漂移。
- 处理策略挂在「类别」而不是具体码上：usage 修调用、environment 可重试或上报、
  internal 快速失败。上层只需要问 `classify(code)`，不用维护一张散落各处的 if 表。
- `case` 覆盖已知码并带 `*)` 兜底到 unknown：新增码漏写分类时落进 unknown，
  汇总行立刻能看出口径对不上。

## 反例

- 用魔法数字直接比较：`if [ "$rc" = 3 ]`——码的含义散落全仓，改一个码全场静默错。
- 类别与动作不匹配：对 usage（调用方 bug）重试三次——重试不会修好调用方的参数错误，
  只是把失败推迟并放大。
