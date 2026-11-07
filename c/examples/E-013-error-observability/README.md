# E-013-error-observability —— 错误可观测性（结构化事件与计数）

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-013 可观测性），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

错误处理只 `perror` 一句人话：日志里翻不到模式、聚不了类、告不了警；
「今天超时多了还是 IO 错多了」这种问题只能靠人肉 grep。错误发生过就过去了，
没有留下任何可计算的痕迹。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-013-error-observability
docker run --rm -v "$PWD":/work -w /work/c/examples/E-013-error-observability \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：4 行结构化事件（seq 单调递增，level/op/code/attempt
齐全），一行计数器汇总 `total=4 timeouts=2 io_errors=1`。

## 为什么这样处理

- 单行 KV 事件是日志管道的通用输入：grep、导入时序库、按 op/code 聚合都直接可用；
  `attempt` 字段让「重试后恢复」可见，避免把最终成功误读为从未失败。
- 事件与计数同源：发事件的地方就是计数的地方，不会出现日志与指标两张皮。
- 虚拟时钟（seq）代替时间戳：教学输出确定；真实代码替换为 ISO8601 时间即可，
  结构不变。

## 反例

- 多行打印一个错误（堆栈式）：日志管道按行切分后上下文断裂，无法聚合。
- 只打计数不打事件：知道「超时多了」，却找不到是哪个 op、第几次尝试。
- 时间戳用本地格式：跨时区机器对不齐，排查时序全乱。
