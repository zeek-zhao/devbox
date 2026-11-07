# E-008-error-reraise —— 不吞错与重抛

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-008 不吞错与重抛），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

数据偶发读不到但程序毫无异常：后来发现中间层有 `err = nil`（「先这样，
回头再处理」）或者把错误打进日志就 `return nil`——调用方拿到的是「假成功」，
要么静默出脏数据，要么到很远的下游才炸。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-008-error-reraise
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-008-error-reraise \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：吞错后调用方看到 success=true（错误丢失）、
只记日志不返回同样是 success=true（日志成唯一线索）、正确重抛得到
`load: cache miss`、重抛后 errors.Is 仍判定到 sentinel。

## 为什么这样处理

- 中间层只有两种合法动作：处理掉（明确理解、可恢复）或重抛（带上下文
  `%w`）。把错误置 nil、只记日志不返回都属于「第三种非法动作」——决策被
  悄悄上移给毫不知情的下游。
- 重抛用 `%w` 不换身份：吞错的另一面不是「不让中间层动错误」，而是动的时候
  用 `fmt.Errorf("load: %w", err)`，上下文加上、身份留着。

## 反例

- `err = nil` 或 `_ = err`：把失败伪装成成功，故障延迟到离根因很远的地方。
- 「记了日志就 return nil」：日志系统一丢、一滚动，这条错误就当没发生过。
- 重抛用 `%v`：等于把别人的错误换成自己的，上游判定链全断。
