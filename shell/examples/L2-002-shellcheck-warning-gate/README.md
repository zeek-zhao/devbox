# L2-002-shellcheck-warning-gate

<!-- coverage: pending -->

## 考点
对应 KP-SH-L2-02：以 `shellcheck -S warning` 将 warning 级诊断作为静态检查门禁。
干净脚本检查通过、含 SC2164 的脚本被门禁拒绝，说明严重级别选择和失败判定有效。

## 易错点
只看默认输出可能漏掉所需严重级别，严重级别选择会影响哪些诊断触发门禁。
验收固定使用 `-S warning`，再修复告警；不要靠屏蔽诊断让检查表面通过。

## 延伸
在提交前检查毕业项目的所有 Shell 脚本，并将 warning 级检查纳入持续集成。
对每条告警修正根因后重新运行门禁，避免只检查单个脚本入口。

## 复现
TAG=latest scripts/run-example.sh shell L2-002-shellcheck-warning-gate
