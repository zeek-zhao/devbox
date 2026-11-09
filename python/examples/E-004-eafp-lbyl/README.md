# E-004-eafp-lbyl —— EAFP 与 LBYL 对照

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-004 EAFP 与 LBYL 对照），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

先检查后使用的 LBYL 写法（`if key in dict`、`if os.path.exists`）在检查与
使用之间有一个窗口：状态可能被并发修改、路径可能被删掉，于是「检查过了」
仍然在使用点炸出异常。写法本身没错，但把检查当成保证是错误认知。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-004-eafp-lbyl
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-004-eafp-lbyl \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：同一配置项在命中与缺失两种情形下，LBYL 与
EAFP 两条路径给出相同结果；末行固定输出结论——EAFP 把检查与使用并成
一个原子步骤，消除 check-then-use 窗口。

## 为什么这样处理

- EAFP（It's Easier to Ask Forgiveness than Permission）是 Python 社区的
  惯用法：直接做，缺失/失败作为异常处理，成功路径没有重复的条件判断。
- LBYL 适用于「检查本身廉价且无副作用、且状态在窗口内稳定」的场景，
  比如纯本地计算前的参数校验。
- 异常路径上必须给出与 LBYL 相同的回退语义（本例的 `default`），
  否则两条路径行为不一致会变成隐性 bug。

## 反例

- 用 `hasattr` / `in` 检查后直接使用，且不处理使用点的异常：窗口期内
  依然会炸，检查给人虚假的安全感。
- 在多线程共享状态上用 LBYL：`if key in d: v = d[key]` 两步之间键可能被删，
  应改用 `d.get()` 或异常处理。
- 把 EAFP 写成「捕一切再猜」：`try` 范围要尽量小，只包住会抛目标异常的语句。
