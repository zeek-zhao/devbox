# E-013-error-aggregation

## 现象
三项输入校验不遇错即停：全错时一次返回 3 条（field + message），
单项错返回 1 条，全对返回空列表（空即成功的信号）。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-013-error-aggregation
```

## 期望输出
```text
bad input: 3 problems
  - name: must not be empty
  - port: must be numeric
  - tags: need at least one
one problem: 1
  - port: must be numeric
valid input: 0 problems
```

## 为什么
异常是「遇第一个错就跳走」的控制流，天然只能报一个错；而校验类
场景的错误往往同时存在多个，抛出式的 fail-first 迫使调用方修一个错
回来再撞下一个错。聚合（收集全部后一次上报）把往返次数从 N 压到 1，
每个 Problem 带 field 名可定位到具体字段。失败率高（用户输入、配置
校验）时用值返回；错误真的是例外（磁盘坏、连接断）才用异常。

## 反例
校验函数发现第一个错就 `throw std::invalid_argument(field)`——一次
只报一个错，调用方像在玩打地鼠；或者收集了却只 `cout` 不返回——
调用方无法编程判断通过与否；或者用 bool 表达「有错」却丢掉明细，
上层只能笼统打一句「参数错误」。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
