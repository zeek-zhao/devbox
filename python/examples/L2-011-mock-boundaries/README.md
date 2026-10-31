# L2-011-mock-boundaries


## 考点
对应 KP-PY-L2-11：用 `unittest.mock` 替换被测代码的外部命令边界。
固定响应被返回且调用次数、参数匹配，说明测试没有启动真实命令并掌握该 KP。

## 易错点
在依赖定义处 patch 不会替换被测模块已经导入的名称。
按模块实际查找名称 patch，并用上下文限定替换作用范围。

## 延伸
对外部文件和网络边界分别注入固定响应及失败结果。
再用 `side_effect` 覆盖命令失败时的异常处理分支。

## 复现
TAG=latest scripts/run-example.sh python L2-011-mock-boundaries
