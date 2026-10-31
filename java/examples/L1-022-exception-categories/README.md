# L1-022-exception-categories

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-22：checked 异常必须捕获或声明，unchecked 异常没有编译期处理要求。
看到未处理 IOException 的编译探针被拒、声明后通过，且 unchecked 可编译并按类型捕获，即说明掌握。

## 易错点
调用受检 API 会阻止编译，因为异常路径未声明或处理；在合适边界 catch 或 throws。
不要吞掉失败；要么处理它，要么让调用方明确承担处理责任。

## 延伸
把 checked 异常放在文件读取边界处理，再将稳定的业务错误交给上层调用者。
比较输入校验抛出的 unchecked 异常与外部 I/O 故障的处理边界。

## 复现
TAG=latest scripts/run-example.sh java L1-022-exception-categories
