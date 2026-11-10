# E-012-message-contract —— 异常消息契约

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-012 异常消息契约），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

异常消息只有 `oops` / `invalid input` 这类空话：接到报错的人必须复现、
加打印、再跑一遍才能定位字段——消息本该一次性回答「哪个字段、收到了
什么、期望什么、下一步做什么」。另一头，消息里直接带 token / 密码的
「上下文」则把日志变成凭证泄露源。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-012-message-contract
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-012-message-contract \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：坏消息 `ParseError('oops')` 三项契约全不达标；
好消息完整携带字段（amount）、实际值（'abc'）、期望（integer）与行动
（act: fix input），三项契约全达标，末行固定输出消息规则。

## 为什么这样处理

- 契约三要素「字段 / 实际值 / 期望」加上行动建议（act: …），让消息
  独立于源码可读：排障者不需要打开实现就能行动。
- 用 repr() 呈现实际值：`'abc'` 与 `abc`、空串与空白在 repr 下不可混淆，
  减少一类经典的「看起来一样实际不同」的误判。
- 敏感值不出现在消息里：上下文靠字段名与类别（见 E-010 结构化日志），
  不靠把凭证打进文本。

## 反例

- `raise ValueError("invalid")`：排障成本被转嫁给每一个接报错的人。
- `raise ValueError(f"auth failed for {token}")`：把凭证写进消息，
  日志系统即凭证泄露面。
- 消息里塞进完整请求体：体积失控且可能包含用户隐私，只留定位所需字段。
