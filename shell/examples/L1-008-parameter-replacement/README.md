# L1-008-parameter-replacement

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-08：`${var/pattern/replacement}` 替换首个匹配，双斜线替换全部。
看到 `aba` 分别变成 `xba` 和 `xbx`，说明首个与全局替换已区分。

## 易错点
`/` 只换首处而 `//` 才换全部；替换模式按 Shell 模式匹配，不是通用正则表达式。
需要替换所有匹配时写 `//`，并用 Shell 通配模式而非正则语法表达匹配范围。

## 延伸
尝试用 `*` 等 Shell 模式清理参数值中的前缀或后缀片段。
为配置规范化编写固定输入测试，覆盖单次和重复匹配两种情况。

## 复现
TAG=latest scripts/run-example.sh shell L1-008-parameter-replacement
