# E-001-exception-hierarchy

## 现象
同一 try 块后有多个 catch 子句，运行只进入其中一条：派生类异常进派生分支，
不同异常类型进各自分支，基类引用捕获派生对象时 `what()` 仍走虚分发。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-001-exception-hierarchy
```

## 期望输出
```text
parse branch: parse failed token=<name>
schema branch: schema failed field=age
sliced-free catch: parse failed
catch-all: unknown throwable
```

## 为什么
catch 子句按书写顺序自上而下做匹配，第一个「能接住」的子句生效，后面的即使类型
更精确也不会再看。所以最派生的类型必须写在最前面，基类（`std::exception` /
`std::runtime_error`）兜底子句放在最后。捕获用 `const std::exception&` 引用，
`what()` 是虚函数，派生类的消息不会丢；若按值捕获会发生对象切片，派生部分被剥掉。

## 反例
把 `catch (const std::runtime_error&)` 写在 `catch (const ParseError&)` 前面：
所有 ParseError 都被基类子句截胡，派生分支不可达，编译器报
「handler will never be reached」一类告警/错误。按值 `catch (std::runtime_error e)`
则切片丢失派生字段，`token()` 之类上下文取不出来。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
