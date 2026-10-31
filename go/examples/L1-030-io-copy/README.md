# L1-030-io-copy

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-30，观察 strings.Reader 的内容经 io.Copy 完整写入 bytes.Buffer。
复制字节数等于输入长度且目标内容一致，说明 Reader、Writer 与 Copy 的组合已掌握。

## 易错点
只检查 io.Copy 的错误会漏掉字节数约定或短写问题；本例同时核对返回数量和内容。
先处理非空错误，再按明确的长度契约检查返回值。

## 延伸
将 bytes.Buffer 换成文件或网络流的 Writer，保持 Reader/Writer 接口不变。
处理大输入时比较直接流式复制与整体读入内存的资源开销。

## 复现
TAG=latest scripts/run-example.sh go L1-030-io-copy
