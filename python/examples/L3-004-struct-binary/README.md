# L3-004-struct-binary

<!-- coverage: pending -->

## 考点
对应 KP-PY-L3-04：用 `struct` 明确字段宽度、字节序和有符号性。
固定格式的字节串、格式长度和解包值均符合预期，说明掌握了该 KP。

## 易错点
本机默认字节序和对齐会让二进制格式随平台变化。
使用显式字节序前缀，并验证长度及解包后的字段值。

## 延伸
为报表缓存格式增加字段版本和兼容性策略。
测试边界整数、截断数据和不合法记录的处理方式。

## 复现
TAG=latest scripts/run-example.sh python L3-004-struct-binary
