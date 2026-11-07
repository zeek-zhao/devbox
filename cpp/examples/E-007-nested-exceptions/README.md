# E-007-nested-exceptions

## 现象
底层抛「offset 16 校验和不符」，中层转译成「build failed」时用
`std::throw_with_nested` 挂上原异常；顶层递归 `std::rethrow_if_nested`
剥出两行完整因果链。对照组普通重抛新异常，nest 为空。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-007-nested-exceptions
```

## 期望输出
```text
depth 0: build failed
depth 1: checksum mismatch at offset 16
plain: plain rethrow, no nest
plain: no nested exception
```

## 为什么
层层转译时最常见的信息丢失是「只抛新异常」：顶层只看到 build failed，
根因（哪个偏移、为什么）永远到不了日志。`throw_with_nested` 把旧异常
作为新异常对象的组成部分带走，`rethrow_if_nested` 在顶层逐层剥开，
因果链完整且类型安全；nest 为空时它安静返回，剥开逻辑可以无差别套用。

## 反例
catch 后 `throw std::runtime_error(\"build failed\");` 直接换新异常——根因
只留在被丢弃的旧对象里；或 `catch (...) { throw; }` 处处空转译，调用栈
每层都打印一遍同一句话却没有增量信息；或者吞掉异常只返回 false，
失败原因彻底消失。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
