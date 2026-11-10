# E-009-assert-contract —— 断言与契约分层

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-009 断言与契约分层），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

把 `assert` 当公共 API 的输入校验：生产环境 JVM 默认关闭断言（不带 -ea），
校验整个消失，非法输入长驱直入；反过来用 `IllegalArgumentException`
表达内部不变量，又把「程序 bug」伪装成「用户错误」，告警等级全错。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-009-assert-contract
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-009-assert-contract \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：-ea 下 assert 开启；内部不变量被打破时抛
AssertionError；公共 API 的空参契约由 requireNonNull 给出固定消息
NullPointerException: id is required；非法金额给 IllegalArgumentException；
末行固定输出分层规则。

## 为什么这样处理

- assert 只守「内部不变量」：表达式假设不可能发生，发生了就是代码 bug，
  生产不带 -ea 时这些检查退场是设计使然——它们不是防线，是调试探针。
- 公共 API 契约用显式类型异常：`Objects.requireNonNull` /
  `IllegalArgumentException` 不受 -ea 开关影响，是无条件的防线。
- 分层标准：调用方可能犯的错 → 类型异常 + 明确消息；只有代码 bug
  才会触发的条件 → assert。

## 反例

- `assert id != null;` 当公共校验：生产（默认 -da）校验消失。
- `throw new AssertionError("invalid input")` 替代 IllegalArgumentException：
  把用户错误标成程序 bug，监控按致命级别告警。
- `Objects.requireNonNull(id)` 之外再手写 `if (id == null) throw new NPE()`：
  语义重复且消息不一致，统一走 requireNonNull 的固定消息。
