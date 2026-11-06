# E-001-error-taxonomy —— 错误分类与类型体系

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-001 错误分类与类型体系），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

同一个失败（比如「没找到」）在不同调用点行为不一致：有的被当成可重试的外部问题重试三次，
有的被当成调用方 bug 直接退出。根因是错误只以一个裸 `int` 往上传，没有统一的
「码 → 类别」体系，每个调用点各自拍脑袋解读。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-001-error-taxonomy
# 或直接在 devbox-cpp 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/c/examples/E-001-error-taxonomy \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：6 个错误码各归入唯一类别，末行是分类汇总
（`usage=2 environment=2 internal=1`）。

## 为什么这样处理

- 错误码用封闭枚举定义，`switch` 覆盖全部枚举值——新增码漏写分支时 `-Wswitch` 编译期报错，
  分类体系不会静默腐化。
- 处理策略挂在「类别」而不是具体码上：USAGE 修调用、ENVIRONMENT 可重试、INTERNAL 快速失败。
  上层只需要问 `classify(code)`，不用维护一张散落各处的 if 表。
- 分类函数对每个码给出唯一归类，保证「同一个码在任何调用点解读一致」。

## 反例

- 用魔法数字直接比较：`if (err == 3)` ——码的含义散落全仓，改一个码全场静默错。
- 类别与动作不匹配：对 `USAGE`（调用方 bug）重试三次——重试不会修好调用方的参数错误，
  只是把失败推迟并放大。
