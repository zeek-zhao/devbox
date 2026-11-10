# E-005-errno-mapping —— errno 与 OSError 子类映射

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-005 errno 与 OSError 子类映射），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

`open()` 失败后只打印 `str(err)` 得到 `[Errno 2] No such file or directory`，
调用方拿着字符串猜该重试还是该跳过；自己写的 `except OSError` 又把「文件缺失」
和「权限不足」混在一起处理，把可自愈的故障当成致命错误。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-005-errno-mapping
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-005-errno-mapping \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：真实触发的缺失文件给出 errno=2 与
FileNotFoundError；合成构造的 EACCES/EAGAIN/EIO 分别落到
DENIED/TRANSIENT/UNKNOWN 三类，每类对应唯一处理动作，末行固定输出映射结论。

## 为什么这样处理

- `OSError` 子类（`FileNotFoundError` / `PermissionError` / `BlockingIOError`…）
  是解释器内置的 errno → 类型映射表：`OSError(errno.ENOENT, ...)` 构造时自动
  返回 `FileNotFoundError` 实例，所以分类先看类型、再看 errno，两层互为表里。
- errno 值是跨版本稳定接口，适合入日志；子类适合做分支。两者都判不出时
  归 UNKNOWN 并快速失败，不猜。
- 分类 → 动作的映射表集中在一处：MISSING 跳过或补建、DENIED 停下上报、
  TRANSIENT 重试、UNKNOWN 快速失败，避免每个调用点各猜各的。

## 反例

- `except OSError: retry()`：把权限问题也重试三次，只是把失败推迟并放大。
- 解析 `str(err)` 里的 `[Errno 2]` 文本分流：消息措辞不可依赖，errno 才是稳定接口。
- 捕获 `BlockingIOError` 却不知道它对应 EAGAIN/EWOULDBLOCK：非阻塞 IO 的
  临时不可用应归 TRANSIENT，不是致命错误。
