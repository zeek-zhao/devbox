# L1-031-assert-invariants


## 考点
对应 KP-PY-L1-31：用 `assert` 表达程序内部不变量，用显式校验处理外部输入。
看到内部条件触发 `AssertionError`、非法输入被明确拒绝，说明掌握了两者边界。

## 易错点
把 `assert` 当用户输入验证会在优化模式下被移除，导致非法输入继续流转。
断言只检查内部不变量；外部输入始终用显式条件和异常校验。

## 延伸
把数据清洗流程拆成输入解析与内部转换阶段，并为每个阶段定义前置条件。
在生产入口对无效数据返回稳定错误信息，而不是依赖断言提示用户。

## 复现
TAG=latest scripts/run-example.sh python L1-031-assert-invariants
