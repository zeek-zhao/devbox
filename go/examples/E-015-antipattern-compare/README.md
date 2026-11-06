# E-015-antipattern-compare —— 反模式对照

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-015 反模式对照），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

四类高频反模式在代码评审里反复出现：按错误文本判定类别（文案一改就误判）、
吞错（失败被伪装成成功）、中间层抢着记日志（一条错误 N 份日志）、把 panic
当流程控制（调用方 recover 出来只有零值，拿不到 error 语义）。单独看每一条
都觉得「能跑」，对照正确写法才看得出它们各自输在哪。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-015-antipattern-compare
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-015-antipattern-compare \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致，四组「反模式 / 正解」对照：文本判定 false 对
errors.Is true、吞错 err=nil 对上抛 err!=nil、中间层多记 1 条对边界记一次、
panic 控制流 recover 得 n=0 对正解 err=disk full。

## 为什么这样处理

- 判定用 `errors.Is`/`errors.As` 沿链匹配身份与类型：错误文本是给人看的，
  改写、加前缀都合法，文本耦合天生脆弱。
- 中间层对错误的合法动作只有两个：处理掉，或带上下文 `%w` 重抛——吞错、
  抢记日志、panic 逃逸都不在其中。
- panic 只表达「程序员 bug」且必须在库边界转成 error（见 E-014）；
  可预期的失败一律用 error 返回，调用方才有分支可写。

## 反例（本例主体即反模式合集，另列两条易漏项）

- `fmt.Errorf("...")` 不带 `%w` 却指望上游 `errors.Is`：上下文加了、链断了。
- 重试、降级等策略写死在错误文本判断上：与 E-010 的 Retryable 声明式判定相反。
