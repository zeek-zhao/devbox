# L1-012-strings-runes


## 考点
对应 KP-GO-L1-12：区分 UTF-8 字节长度、rune 数量和按字节索引。
看到同一字符串的字节数、rune 数和首个 rune 分别符合编码内容，说明掌握了区别。

## 易错点
`len(s)` 返回字节数而不是字符数，多字节文本会让两者不同。
按 rune 遍历文本；只有处理协议或原始编码时才按字节访问。

## 延伸
练习在 UTF-8 文本中记录 rune 位置，同时保留原始字节偏移。
比较按字节切片与按 rune 遍历在多字节字符上的结果。

## 复现
TAG=latest scripts/run-example.sh go L1-012-strings-runes
