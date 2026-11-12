# E-014-fail-fast —— 不可恢复与快速失败

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-014 不可恢复与快速失败），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 考点

库内部 panic 可以暴露程序员不变量错误；库边界应 recover 一次并用 `%w` 转为带 sentinel 的 error，进程边界再决定快速失败。对上契约是 `ErrInvariant`，不是 panic 文本。

## 易错点

- 到处 `defer recover()` 会把 bug 吞掉，程序可能以未定义状态继续运行。
- goroutine 的 panic 无法由其他 goroutine recover；试图跨 goroutine 接住会导致进程崩溃。
- 真跑对照：同一不变量 panic 被吞掉后返回零结果且无错误，错误路径表现为 `zero-without-error`；在库边界 recover 并包装后，`errors.Is` 能识别 `ErrInvariant`。样例只把结果作为 stdout 期望数据，不让 panic 或业务错误逃逸成 CI 失败。

## 复现

```bash
TAG=latest bash scripts/run-example.sh go E-014-fail-fast
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-014-fail-fast \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

逐行输出应与 `expected.txt` 一致：正常输入得到 n=16；不变量破坏后边界 recover 转为 error，策略层模拟快速失败；`errors.Is` 确认错误身份是 `ErrInvariant`。

## 延伸

- recover 只应放在明确的库边界；转换时用 `%w` 保留机器可判定的身份。
- 对不可恢复错误，进程边界宁可快速失败，也不要把坏结果继续写入存储。
