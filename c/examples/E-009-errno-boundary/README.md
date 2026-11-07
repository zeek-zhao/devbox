# E-009-errno-boundary —— 边界转换与错误码映射

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-009 边界转换与错误码），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

应用自己的错误码是 1/2/3，库函数却往 errno 里塞 34、2、13——调用链上半段
一会儿判 errno 一会儿判应用码，两套体系混用；有人在三层深处直接 `if (errno == ERANGE)`，
而那时 errno 早被中间的 printf 改写了。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-009-errno-boundary
docker run --rm -v "$PWD":/work -w /work/c/examples/E-009-errno-boundary \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三行 strtol 边界转换（正常 / ERANGE=34→应用码 2 /
尾随垃圾→应用码 1），两行 open 系 errno 映射（ENOENT=2、EACCES=13 → 应用码 3）。

## 为什么这样处理

- errno 在失败后立即保存（L2-014 的纪律），保存值随结果一起上浮留痕；
  翻译动作只发生在边界层一处，翻译点之后全链路只认应用码。
- EACCES 与 ENOENT 同映射为「拿不到」是显式策略：对调用方，权限不足与不存在
  的处置相同；需要区分时在映射表里加行即可，改一处而非改全链路。
- 输出打 errno 数字值而非 strerror 文案：数字是 POSIX 固定的，文案随 locale 漂移。

## 反例

- 边界不转换、让 errno 一路裸传：中途任何一次库调用都可能改写 errno，深处的判断靠运气。
- 每个调用点各自 if-else 翻译 errno：同一 ENOENT 在十处有十种解释，口径漂移。
