# L2-006-sanitizers


## 考点
对应 KP-L2-06：用 AddressSanitizer 检查一次堆缓冲区越界写入，并将报告归一化输出。
看到固定的 `asan: heap-buffer-overflow`，即说明消毒器发现了目标缺陷。

## 易错点
ASan 报告包含地址且故意以非零状态结束，直接透传会造成输出不稳定并让 runner 失败。
仅在此用例中捕获程序输出和退出状态，确认报告类型后再输出固定结果。

## 延伸
可分别启用 UBSan 检查未定义行为，并为 ASan 与 TSan 使用独立构建。
再对索引和查询路径添加正常测试，验证消毒器仅报告真实触发的缺陷。

## 复现
TAG=latest scripts/run-example.sh cpp L2-006-sanitizers
