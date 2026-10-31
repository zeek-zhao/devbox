<!-- coverage: pending -->

# L2-007-ubsan-overflow —— 让 UBSan 报告有符号整数溢出

## 考点

- UndefinedBehaviorSanitizer 监测执行期间的有符号整数溢出。
- `-fno-sanitize-recover=undefined` 让首次诊断立即终止程序。

## 为什么这么写

溢出操作使用 volatile 输入，避免编译器在编译期折叠；脚本匹配运行时诊断，而不是依赖退出码的偶然表现。

## 易错点

- 有符号溢出是未定义行为，不能把某个回绕结果当作标准保证。
- 默认恢复模式可能继续执行；需要失败即停时显式关闭 sanitizer 恢复。

## 运行

```bash
TAG=latest scripts/run-example.sh c L2-007-ubsan-overflow
```
