# E-003-exception-chaining —— 异常链的三种形态

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-003 异常链的三种形态），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

在 `except` 块里抛新异常时，三种写法的因果记录完全不同：直接 `raise 新异常`
原异常只留在隐式 `__context__`（不承诺因果）；`raise 新异常 from 原异常`
把因果显式写进 `__cause__`；裸 `raise` 让同一个异常对象原样继续传播。
排查时读错字段会把「伴随发生」误判成「根因」，或者丢掉唯一线索。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-003-exception-chaining
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-003-exception-chaining \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：隐式链 cause=None / context=ValueError；
显式链 cause=ValueError；裸重抛传播的是同一个异常对象（same-object=True）
且不产生新链。

## 为什么这样处理

- 「我就是因为它才失败」用 `raise ... from err`：`__cause__` 是显式声明的
  因果，traceback 末尾固定打印 `The above exception was the direct cause`。
- 「顺便发生、不是原因」不写 from：解释器仍把前一异常放进 `__context__`
  供排查，但不冒充因果。
- 在 `except` 块里要原样继续传播时用裸 `raise`：对象不变、traceback 变长，
  不会因 `raise err` 的写法差异意外生成隐式链。

## 反例

- 在 `except` 里 `raise NewError("failed")` 还自以为保留了原因——原因只进了
  `__context__`，任何按 `__cause__` 找根因的代码都拿不到。
- `raise NewError(str(err))` 复制消息当「包装」：类型信息丢失，类型分流失效。
- 不知道改抛新异常后 traceback 有两段栈：排查者要能分清哪段是根因
  （依赖本例的字段语义：`__cause__` 显式因果优先读）。
