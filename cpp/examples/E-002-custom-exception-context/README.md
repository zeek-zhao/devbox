# E-002-custom-exception-context

## 现象
自定义异常继承 `std::runtime_error`，除了 `what()` 概要消息，还带着
path/line/code 三个上下文字段；catch 处直接读字段得到定位信息。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-002-custom-exception-context
```

## 期望输出
```text
load: failed what=index file corrupt
load: path=data/index.bin line=7 code=3
outer: summary=index file corrupt
```

## 为什么
只抛 `std::runtime_error("load failed")` 这类一句字符串，上层 catch 到以后
只能再打印一句「load failed」，定位还要靠人肉重放。把「哪个文件、哪一行、
错误码几号」做成异常类型的字段随身携带，catch 处读字段即可恢复现场；
字段访问器是有类型的，拼错字段名在编译期就能发现。上层不需要细节时按基类
捕获，`what()` 的虚分发仍然给出概要，不破坏分层。

## 反例
把所有上下文拼成一个大字符串塞进 `what()`：上层想取某个字段只能再解析
字符串，格式一改就崩；或者直接 `throw 1`/`throw "msg"` 抛裸值，catch
处既拿不到类型信息也无法与其他模块的异常统一处理。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
