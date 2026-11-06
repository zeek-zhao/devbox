# E-005-error-identity —— 错误身份判定（码比较 vs 文本匹配）

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-005 错误身份判定），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

判定错误类别用 `strstr(msg, "timed out")` 这类文本匹配：锁等待超时的消息里也有
"timed out"，于是死锁/锁竞争被当成网络抖动去重试网络，真正的锁问题原地复现。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-005-error-identity
docker run --rm -v "$PWD":/work -w /work/c/examples/E-005-error-identity \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：前两行显示文本匹配与码匹配对网络超时结论一致；
第三行是定量反例——`db-txn` 按码是 LOCK_STALL、按文本被误判成 NET_TIMEOUT；
末行显示哨兵码比较恰好命中 1 个。

## 为什么这样处理

- 身份判定只比码（哨兵 + `err_is`）：码是契约的一部分，不会随文案调整漂移。
- 文本匹配的失效模式是双向的：既会把别的错误判进来（本例），也会因改文案漏判出去。
  教学上保留这条反例通道，是为了让「为什么禁止文本匹配」可被演示而不是靠背。

## 反例

- `strstr(msg, "timeout")`、正则匹配错误文案——两类同词错误互相污染（本例第三行）。
- 用 `what` 字符串 `strcmp` 当身份：`what` 供人读，改一个词就断上游匹配。
