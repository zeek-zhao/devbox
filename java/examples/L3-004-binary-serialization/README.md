# L3-004-binary-serialization

<!-- coverage: pending -->

## 考点
对应 KP-JV-L3-04：用 DataOutputStream/DataInputStream 定义显式大端二进制协议。
固定记录往返一致、整数编码为 `01 02 03 04`，且错误头、越界长度与截断均被拒绝，说明协议边界可靠。

## 易错点
未约定字节序会造成跨端错值；未校验长度就分配可能耗尽内存。
先校验 magic、版本与长度上限，再读取载荷；不要把对象原始布局直接落盘。

## 延伸
为倒排表协议增加字段版本迁移，并保留对旧格式的明确拒绝测试。
用 ByteBuffer.order(LITTLE_ENDIAN) 扩展一种有明确标记的小端格式。

## 复现
TAG=latest scripts/run-example.sh java L3-004-binary-serialization
