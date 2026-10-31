# L2-011-jshell-experiments

<!-- coverage: pending -->

## 考点
对应 KP-JV-L2-11：用 jshell 运行固定表达式脚本，并以编译版验证兜底。
脚本无错误记录且含 `repl: ok`，编译版也打印 `compiled: ok`，说明批处理结果经过显式验收。

## 易错点
jshell 的交互诊断与批处理退出状态不是一回事，脚本错误仍可能看似成功。
同时检查错误记录与业务标记，并用 javac/java 对同一表达式作验收兜底。

## 延伸
将查询表达式改为可复用方法，并比较 jshell 探索与编译测试的职责边界。
为批处理脚本增加错误用例，确认缺少业务标记时验收失败。

## 复现
TAG=latest scripts/run-example.sh java L2-011-jshell-experiments
