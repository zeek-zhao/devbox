<!-- coverage: pending -->

# L3-021-struct-serialization —— 读取旧版本记录并补齐新字段

## 考点

- 定义 v1、v2 不同布局的业务结构。
- 使用明确字节序的字段编码，而不是直接写入结构体对象表示。
- 将 v1 解码到 v2，并为新字段提供默认值。

## 为什么这么写

固定字节格式不受结构体 padding 和本机字节序影响；版本号决定字段是否存在。

## 易错点

- `fwrite(struct)` 会把 padding 一并写出且不能保证跨平台。
- 读取旧版数据时必须初始化新版缺失字段的默认值。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-021-struct-serialization
```
