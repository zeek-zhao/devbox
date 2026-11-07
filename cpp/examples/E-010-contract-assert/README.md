# E-010-contract-assert

## 现象
同一程序两层校验并行：`parse_port` 对空串/含非数字输入返回
`std::nullopt`（永远执行的输入校验）；`to_mask` 用 `assert` 守
「port 在 0..65535」这一内部不变式（上游已保证，debug 构建生效）。
输出里 assert: active=true 证明本例跑在 assert 生效的构建里。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-010-contract-assert
```

## 期望输出
```text
empty: ok=false
junk: ok=false
good: value=8080 mask=144
boundary: value=1 mask=1
assert: active=true
```

## 为什么
assert 的语义是「此处为真，否则是程序自身的 bug」：NDEBUG 一定义它
整体消失，所以它只能守内部不变式（上游已经用类型/校验保证的条件），
不能挡用户输入——release 构建里坏数据会直接穿过。用户输入走错误值/
错误码路径，永远存在。两层各司其职：把用户输入交给 assert 的项目，
release 版会静默接受非法数据；把内部不变式写成错误码的项目，代码里
充满「不可能发生」的分支，真实 bug 反而被稀释。

## 反例
`assert(!input.empty())` 挡空输入：NDEBUG 构建下直接放行，下游
`stoi` 抛出未处理异常；或者 release 里用 `#define NDEBUG` 前先跑过
的调试逻辑忘了删；或者 assert 里放副作用表达式（`assert(fclose(f) == 0)`）——
NDEBUG 一下副作用整个消失，行为漂移。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
