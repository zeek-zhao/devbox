<!-- coverage: exempt Sanitizer 是独立测试工具，不构成 HTTP 服务功能。 -->

# L2-006-asan-bounds —— 用 AddressSanitizer 定位堆缓冲区越界

## 考点

- AddressSanitizer 运行时检测堆分配对象之外的写入。
- 将 sanitizer 的崩溃报告留在 stderr，只把稳定判定写到 stdout。

## 为什么这么写

程序故意写到四字节堆数组之后，运行脚本必须从诊断中找到 `heap-buffer-overflow`，不能把任意非零退出都当作成功。

## 易错点

- 只检查程序退出非零会把无关崩溃也判成检测成功。
- sanitizer 报告写入 stderr 且格式随工具链变化，不应进入期望输出。

## 运行

```bash
TAG=latest scripts/run-example.sh c L2-006-asan-bounds
```
