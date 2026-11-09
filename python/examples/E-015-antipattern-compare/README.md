# E-015-antipattern-compare —— 错误处理反模式对照

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-015 错误处理反模式对照），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

三类高频反模式让故障「看起来在跑、实际已坏」：`except: pass` 把失败
吞进无日志的黑洞；按消息文本分流分类，措辞一改行为就漂移；裸 `except`
连 `KeyboardInterrupt` / `SystemExit` 一并吞掉，用户按 Ctrl-C 都杀不死。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-015-antipattern-compare
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-015-antipattern-compare \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三组反模式/修复对照——吞错 vs 结构化记录
（JSON 单行）、文本分流 vs 类型分流、裸 except 吞 Ctrl-C vs 让
BaseException 逃逸到调用方，末行固定输出三条规则。

## 为什么这样处理

- 吞错的正确替代不是「不吞」，而是「记录后再决定」：结构化单行 JSON
  （code + message）与 E-010 的日志契约同构，机器可检索。
- 分流靠类型不靠文本：`isinstance` 分支在措辞改动下行为不变；
  文本匹配的脆弱性用「disk-full 不含 timeout 却被文本分流误读」演示。
- `except Exception` 与裸 `except` 的分界线是 BaseException：让
  Ctrl-C / SystemExit 逃逸是程序可终止的底线，任何兜底都不应越过。

## 反例

- 反模式自身即本例演示对象：`except: pass`、`except:`、文本分流
  ——三者在真实事故里分别对应「无日志可查」「分类静默漂移」「杀不死」。
- noqa 演示用注释只标注在反模式行：正确路径的写法必须零豁免，
  避免「教学豁免」扩散成常规写法。
