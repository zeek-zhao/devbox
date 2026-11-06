# E-007-defer-cleanup —— 资源清理

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-007 资源清理），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

两种清理事故：一是错误路径提前 return 时忘了关闭资源（泄漏）；二是
`defer f.Close()` 的返回值被随手丢掉——磁盘满时写「成功」，数据实际没落盘；
三是清理失败错误覆盖了真正的主错误，排查方向被带偏。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-007-defer-cleanup
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-007-defer-cleanup \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：主错误优先（write 错误不被 close 错误覆盖）、
主流程成功时清理错误对外可见、成功路径资源确实被关闭、错误路径 defer 清理
照样执行（steps=[open close]）。

## 为什么这样处理

- defer 在 return 之后、函数退出之前执行，错误路径也会走到——把 Close 注册
  在拿到资源之后，资源生命周期与函数作用域绑定，不再依赖每个分支手写关闭。
- 命名返回值 `(err error)` 让 defer 里的闭包能改写最终错误：合成规则是
  「主错误优先」，主流程已失败时清理错误只让路（避免掩盖根因），主流程成功
  时清理错误才成为返回错误——两条路都不静默。

## 反例

- `defer f.Close()` 丢掉返回值：写缓存的程序在磁盘满时「成功」返回，数据丢失。
- 清理错误无条件覆盖主错误：`err = f.Close()` 把真正的根因换成 close 报错。
- 在错误分支手工逐个关闭：加一个提前 return 就漏一处，泄漏随代码增长。
