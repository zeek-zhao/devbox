<!-- coverage: pending -->

# L2-014-errno-handling —— 在失败调用后立即保存 errno

## 考点

- 打开不存在的文件，确认 `fopen` 失败并立即保存 `errno`。
- 使用 `strerror` 把保存的错误码转换为稳定文本。

## 为什么这么写

失败路径不在读取 `errno` 前调用其他库函数，并用临时目录中的专属缺失文件避免受仓库内容影响。

## 易错点

- `errno` 不是每次调用都会清零，成功调用后读它可能拿到旧值。
- 先调用日志或格式化函数再取错误码，可能覆盖原始失败原因。

## 运行

```bash
TAG=latest scripts/run-example.sh c L2-014-errno-handling
```
