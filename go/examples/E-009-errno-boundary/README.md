# E-009-errno-boundary —— 边界转换与错误码

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-009 边界转换与错误码），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

标准库调用失败后，程序要么直接 `panic`、要么 `os.Exit(1)` 一刀切——调用方
（脚本、调度器）无法区分「文件不存在」（该初始化）和「权限拒绝」（该报障）；
另一头，代码里散落 `strings.Contains(err.Error(), "no such file")` 的判定，
换个系统/locale 就失效。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-009-errno-boundary
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-009-errno-boundary \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：os.ReadFile 报出的标准库诊断文本、errors.As 取出
*fs.PathError、fs.ErrNotExist→码 3、*strconv.NumError→码 2、成功→0、
未知兜底→70。

## 为什么这样处理

- 标准库的错误约定是「包级 sentinel（fs.ErrNotExist）+ 包装类型
  （*fs.PathError）」：sentinel 答「是什么原因」，包装类型答「在哪个文件、
  哪个操作」。用 errors.Is/As 解码，而不是解析错误文本。
- 在系统边界把解码结果映射成稳定的错误码（退出码、gRPC code 等）：
  上游只依赖码表，不依赖错误文本，码表稳定即契约稳定。

## 反例

- `strings.Contains(err.Error(), "not exist")`：文本是给人看的诊断，不是
  契约，任何一端改写即断。
- 一切失败都 exit 1：调用方无法区分可自动恢复与需人工介入的失败。
- 忽略未知错误类别就归入已知类别：宁可给「未知」单独一个兜底码。
