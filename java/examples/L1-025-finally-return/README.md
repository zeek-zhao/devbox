# L1-025-finally-return

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-25：finally 会参与控制流，内部 return 能替换待完成的返回或异常。
看到 finally 的 return 覆盖原返回并吞掉异常，而只做清理时异常仍可捕获，即说明掌握。

## 易错点
原返回值或异常会消失，因为 finally 的 return 替换待完成控制流。
finally 只做清理，不 return，也不遮盖原错误。

## 延伸
把资源释放交给 try-with-resources，避免在 finally 中编写会改变控制流的清理逻辑。
检查异常展开路径，确保清理失败不会意外替换业务失败。

## 复现
TAG=latest scripts/run-example.sh java L1-025-finally-return
