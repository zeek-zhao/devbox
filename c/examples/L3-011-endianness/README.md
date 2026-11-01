<!-- coverage: pending -->

# L3-011-endianness —— 检测本机字节序并手动翻转字节

## 考点

- 通过 `union` 观察多字节整数的内存表示。
- 手动交换 32 位整数的四个字节。

## 为什么这么写

本机序只决定打印 `little` 或 `big`，字节翻转则对固定值给出跨平台一致结果。

## 易错点

- 不要把本机永远假定为小端。
- 按位移位时用无符号整数，避免有符号移位的未定义行为。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-011-endianness
```
