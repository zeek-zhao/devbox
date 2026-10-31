# L1-024-resource-closing

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-24：try-with-resources 按声明逆序关闭 AutoCloseable 资源。
看到正常与异常路径都按后开先关关闭，且主体异常保留、close 错误进入 suppressed，即说明掌握。

## 易错点
手动 finally 中抛出关闭错误可能遮住业务错误；try-with-resources 会保留主体异常。
检查 getSuppressed 才能发现关闭阶段的附加失败。

## 延伸
练习把真实文件流放入 try-with-resources，并在读取失败时保留主体原因。
比较多个资源的声明顺序与实际关闭顺序，明确资源生命周期边界。

## 复现
TAG=latest scripts/run-example.sh java L1-024-resource-closing
