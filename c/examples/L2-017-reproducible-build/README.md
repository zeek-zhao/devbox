<!-- coverage: pending -->

# L2-017-reproducible-build —— 比较归一化路径后的二进制构建结果

## 考点

- 用相同源文件和编译参数独立构建两次。
- `-ffile-prefix-map` 归一化源路径，再逐字节比较可执行文件。

## 为什么这么写

比较整个二进制而非受格式影响的文本摘要；先归一化编译路径，避免工作目录写入调试信息造成伪差异。

## 易错点

- 不同输出文件名或嵌入绝对路径会掩盖构建输入相同这一事实。
- 比较某一条 `size` 输出不足以发现二进制中其他字节的变化。

## 运行

```bash
TAG=latest scripts/run-example.sh c L2-017-reproducible-build
```
