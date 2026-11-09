# E-002-except-order —— except 匹配顺序与宽窄选择

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-002 except 匹配顺序与宽窄选择），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

多个 `except` 子句写在一起时，宽类型写在前面会把后面的具体类型全部吞掉：
`except Exception` 排第一，`except ValueError` 就永远轮不到。故障被宽处理器
接走后按错误的策略处理（该拒绝的被重试），且不报错、只在结果上漂移。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-002-except-order
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-002-except-order \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：具体类型处理器先命中（ValueError），
同级类型用元组一次捕获（KeyError），宽 `Exception` 兜底只收到前两条
都没接住的 RuntimeError，末行固定输出匹配顺序规则。

## 为什么这样处理

- `except` 子句按书写顺序自上而下匹配，第一条命中的生效——所以子类处理器
  必须写在父类处理器之前。这是解释器语义决定的固定规则，不是风格偏好。
- 同级且处理方式相同的类型（`TypeError` / `KeyError`）用元组合并成一条，
  减少重复处理代码；处理方式不同的不要合并。
- 宽 `Exception` 只作为最后一条兜底，并且要记录或转译，不能只 `pass`。

## 反例

- `except Exception` 写在第一条：后面所有具体类型成为死代码，静态检查不报错。
- 兜底后不区分类型统一重试：把不可恢复错误当临时故障，只是推迟并放大失败。
- 依赖「错误消息文本」分流而不写具体类型：文本一改分流就静默失效。
