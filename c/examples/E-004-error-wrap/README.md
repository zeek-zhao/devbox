# E-004-error-wrap —— 传播与包装

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-004 传播与包装），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

三层调用里最底层报「open failed」，到了顶层只剩 `boot failed, code=1`——
是配置文件没了还是权限不对？哪一层把它吞成了泛化码？没有包装机制，
错误一多层就失真，排障只能逐层加 printf。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-004-error-wrap
docker run --rm -v "$PWD":/work -w /work/c/examples/E-004-error-wrap \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：一行完整错误链 `load_settings: read_config: open failed`，
一行根因信息 `root_code=3 depth=2`——包装了两层，根因码仍是 3。

## 为什么这样处理

- 每层 wrap 只加前缀不改码：错误身份全程稳定，上游按根因码精确匹配的代码
  不因中间层数变化而失效。
- 消息链天然就是排障路径：从左到右即调用链，定位「断在哪一节」不需要重新复现。
- `depth` 有上限（MAX_FRAMES），防御循环包装把消息撑爆缓冲。

## 反例

- 每层把码改写成本层的泛化码（`return -1`）：根因丢失，上游无法区分「文件没了」和「盘挂了」。
- 每层把消息整个替换：顶层只看到最后一层的话，前几层的上下文全灭。
