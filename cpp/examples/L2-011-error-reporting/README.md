# L2-011-error-reporting

<!-- coverage: pending -->

## 考点
对应 KP-L2-11：错误值携带枚举类别和上下文，用户输入错误与内部失败输出不同诊断。
看到空查询指向 `query term` 且状态为 2，模拟存储失败指向 `documents/index.txt` 且状态为 3，说明能区分并定位错误。

## 易错点
只返回通用失败或吞掉异常会丢失失败操作与对象上下文。
用错误码枚举配合明确消息，并由调用方映射状态码；脚本接住预期状态而不把它当运行失败。

## 延伸
可以把错误值扩展为 `std::expected` 风格结果，让成功值与失败上下文共用类型安全接口。
再为路径缺失、权限错误和损坏数据建立稳定的诊断分类。

## 复现
TAG=latest scripts/run-example.sh cpp L2-011-error-reporting
