# E-003-error-match —— 捕获与精确匹配

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-003 捕获与精确匹配），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

中间层加了 `fmt.Errorf("handle request: %w", err)` 之后，调用方
`if err == ErrNotFound` 永远不成立——错误明明发生了，匹配却失灵；
另一头，两条逾期天数不同的记录想按「都超过 30 天即违约」归为同一类，
`==` 与默认比较都无能为力。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-003-error-match
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-003-error-match \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：== 在包装后失配（false）、errors.Is 沿链命中目标
sentinel（true）、对无关错误排他（false）、自定义 Is 按业务规则命中 45 天
排除 5 天。

## 为什么这样处理

- `==` 只比较接口二元组，包装一层后 `(类型, 值)` 全变；`errors.Is` 沿
  `Unwrap` 链逐层比较，包装不破坏匹配。
- 自定义 `Is(target error) bool` 是标准库留的扩展点：`errors.Is` 先做相等
  比较，再逐层询问 `Is` 方法，业务匹配规则（30 天阈值）可以收敛到类型自身，
  而不是散落在每个调用点的 if 里。

## 反例

- 包装后继续用 `==` 匹配——中间层加一次 `%w`，调用方的分支就永久失灵。
- 匹配用字符串：`err.Error() == "record not found"`——文本微调即静默失配，
  且无法表达「同一类」的语义。
