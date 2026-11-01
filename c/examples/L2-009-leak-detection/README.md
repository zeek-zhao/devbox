

# L2-009-leak-detection —— 在进程退出时检查未释放内存

## 考点

- AddressSanitizer 的 LeakSanitizer 在进程退出时扫描遗留分配。
- 脚本要求诊断包含 `LeakSanitizer`，而非仅依据退出码判断。

## 为什么这么写

程序保留一笔可达性明确的堆分配而不释放；运行日志完整捕获到进程退出后，再检查泄漏诊断。

## 易错点

- 泄漏检测发生在进程退出阶段，中途检查日志可能看不到报告。
- 不同工具链的报告细节会变动，只匹配稳定诊断标记。

## 运行

```bash
TAG=latest scripts/run-example.sh c L2-009-leak-detection
```
