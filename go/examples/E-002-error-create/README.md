# E-002-error-create —— 创建与抛出

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-002 创建与抛出），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

两种常见「创建错误」事故：一是错误文本不带任何数据，排查时只知道 failed 不知道
哪个端口、第几次；二是函数成功时返回了具体指针类型的 nil，调用方拿到的
`error` 接口却 `!= nil`，好端端的成功路径被误判成失败。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-002-error-create
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-002-error-create \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：errors.New 静态错误、fmt.Errorf 带数据创建、
typed-nil 陷阱（ok 场景 err!=nil=true）、正确写法（err==nil=true）、
自定义类型稳定诊断行。

## 为什么这样处理

- 静态文本（可当 sentinel 复用的）用 `errors.New`；带运行时数据的用
  `fmt.Errorf` 动词构造——数据进文本，诊断时不用翻源码猜。
- typed-nil 陷阱的根源是接口值 = (类型, 值) 二元组：`(*T)(nil)` 装进 `error`
  接口后类型非空，接口就不等于 nil。防法是约定「返回 error 的函数，签名与
  返回值都用 error 接口」，成功路径显式 `return nil`。

## 反例

- 返回 `(*ConfigError)(nil)` 当成功——调用方 `if err != nil` 必中，成功被误报。
- 创建错误不带数据：`errors.New("invalid port")` 永远不知道错的是哪个端口。
