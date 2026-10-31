# L1-003-quoting-word-splitting


## 考点
对应 KP-SH-L1-03：未引用展开会按 IFS 拆词并进行路径名展开，引用展开保留整体。
看到未引用值拆成单词且 `*.txt` 匹配两个文件，而引用值保持一个参数，即为掌握。

## 易错点
未加引号的变量会按 `IFS` 拆词并进行路径名展开，数据可能意外变成多个参数。
ShellCheck 将 SC2086 列为 info 级，`-S warning` 不报告它；用 `-S info` 可检查此反例。
默认将数据展开写成 `"$value"`，只有确实需要拆分和通配时才不引用。

## 延伸
用数组保存多个参数，并以 `"${array[@]}"` 保留每个元素的边界。
为含空格或通配符的配置路径增加测试，确认引用后仍作为单个参数传递。

## 复现
TAG=latest scripts/run-example.sh shell L1-003-quoting-word-splitting
