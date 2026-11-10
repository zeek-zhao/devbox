# E-002-cause-chain-walk —— cause 链多层包装与根因提取

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-002 cause 链多层包装与根因提取），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

跨层包装时只复制消息不带 cause：`new ImportException(e.getMessage())`
让顶层异常看起来「完整」，但根因（磁盘扇区错误）彻底丢失；排障时只能
看到「import 失败」，看不到「为什么失败」，也说不清包装了几层。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-002-cause-chain-walk
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-002-cause-chain-walk \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三层链（ImportException → StorageException →
IOException）逐层可读，`rootCause` 沿 `getCause` 走到底取出根因
（java.io.IOException: sector unreadable），chain-depth=3 印证层级。

## 为什么这样处理

- 包装构造器必须用 `(message, cause)` 二参版本：cause 是链的生命线，
  丢了就只剩一条没有来路的消息。
- `rootCause` 沿 `getCause()` 走到 null 并防御自指（cause == self）：
  根因提取是日志/上报的标准动作，不依赖打印整段栈。
- 边界处包装时在消息里补业务上下文（"read path docs/7"）：根因回答
  「底层怎么了」，业务消息回答「在做什么时失败的」，两者互补。

## 反例

- `new ImportException(e.getMessage())`：根因丢失，`getCause()` 为 null。
- 每层都重新 new 异常并复制消息：链变成平铺的一串无因果消息。
- 只在顶层 `printStackTrace()`：生产日志里整段栈噪声大且难检索，
  结构化的 cause 遍历才是可编程的根因提取。
