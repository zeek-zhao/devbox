# L1-026-read-lines

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-26：用 `while IFS= read -r line` 逐行读取并保留原始行内容。
看到前导空格、行尾空格和反斜线都仍在输出中，即说明掌握了保留规则。

## 易错点
默认 `read` 会处理反斜线，默认 `IFS` 还会裁掉行首与行尾空白。
用 `IFS=` 和 `-r` 读取，避免配置行或清单内容被悄悄改写。

## 延伸
把读取循环用于配置文件或清单，并在保留原文后再进行有意的解析。
测试空行、包含空格的路径和反斜线，确保每条输入都按原样处理。

## 复现
TAG=latest scripts/run-example.sh shell L1-026-read-lines
