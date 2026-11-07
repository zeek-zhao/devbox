# E-006-error-code-enum

## 现象
错误用 `enum class Errc` 返回：`remove_entry` 对空键返回 BadInput、对
不存在键返回 NotFound；`to_exit_code` 统一把错误码映射成进程退出码
（BadInput=1，业务失败 NotFound/Conflict=0）。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-006-error-code-enum
```

## 期望输出
```text
alpha: ok exit=0
empty: bad input exit=1
ghost: not found exit=0
ghost: raw=4
```

## 为什么
`enum class` 收紧了错误码：不隐式转 int，别的模块想传任意整数进来
编译不过；switch 漏一个枚举值编译器还能告警。退出码映射集中到一个
函数里，「哪些错误算程序故障、哪些算正常业务结果」的口径改一处即可，
不会出现一半调用点 `return 3`、一半 `return 1` 的漂移。错误码适合
失败率高、就地处理的路径（如查询未命中），异常适合「跨多层向上冒」
的故障——两者的选择标准是调用方大概率怎么处理。

## 反例
直接返回 int 魔法数字（`return 7;`）：调用方和定义方各写一份字面量，
改一处忘一处；或者把 enum class 隐式当 bool/int 用（编译不过但会逼出
`static_cast` 满天飞）；或者退出码不做约定，NotFound 返回 1、BadInput
也返回 1，脚本侧无法区分「程序坏了」和「没查到」。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
