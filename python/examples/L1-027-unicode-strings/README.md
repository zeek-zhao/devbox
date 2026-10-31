# L1-027-unicode-strings

<!-- coverage: pending -->

## 考点
对应 KP-PY-L1-27：区分字符串的 Unicode 码点数量与 UTF-8 编码后的字节长度。
同一字符串的字符数与编码字节数分别输出且数值不同，说明掌握文本索引和字节边界的区别。

## 易错点
把 `len(str)` 当成 UTF-8 字节数，会在协议偏移和缓冲区长度计算中产生错误。
跨字节协议边界时显式编码为 UTF-8，并对 `bytes` 计算长度。

## 延伸
可以继续比较不同 Unicode 字符的 UTF-8 字节长度和字符串切片结果。
在文件或网络接口处明确编码，避免把文本字符索引当成字节偏移。

## 复现
TAG=latest scripts/run-example.sh python L1-027-unicode-strings
