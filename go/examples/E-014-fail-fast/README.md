# E-014-fail-fast —— 不可恢复与快速失败

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-014 不可恢复与快速失败），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

不变量被破坏后程序选择「带病运行」：符号表缺了条目就当 0 继续算，错误结果
一路写进存储；或者相反——库函数随手 panic 穿透三层调用栈，把可预期的坏输入
放大成整个进程崩溃，谁也不知道该在哪一层接。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-014-fail-fast
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-014-fail-fast \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：正常输入 n=16、不变量破坏时边界 recover 转成
带 sentinel 的 error（n=0，进程不崩）、策略层按 sentinel 判定后快速失败
（打印代替真实 exit(70)）、errors.Is 确认契约是 ErrInvariant 而非 panic 文本。

## 为什么这样处理

- 分层分工：库内部 panic 表达「这不该发生」（程序员 bug，立即暴露优于带病
  运行）；库边界 recover 一次、转成 `fmt.Errorf(..., %w, ErrInvariant)`，
  panic 文本只是诊断细节，对上契约是 sentinel。进程边界对不可恢复错误
  快速失败（log.Fatal / 非零退出），宁可停止服务也不产出坏数据。
- recover 必须配 `%w` 转换：只 recover 不转换等于把 panic 换成静默。

## 反例

- 到处 `defer recover()` 当兜底：bug 被到处吞，程序以未定义状态继续跑。
- 在 goroutine 里指望别人 recover：goroutine 的 panic 无法被其他 goroutine
  接住，进程必崩。
- 对不变量错误「先记日志继续跑」：坏数据落库的代价远大于一次快速失败。
