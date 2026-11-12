# L2-014-config-allowlist-load

## 考点
对应 KP-SH-L2-14：配置文件按键白名单加载，白名单外的键被拒绝并计入报告，而不是静默生效。

## 易错点
用通配解析会把未知键直接赋给动态变量，攻击面与拼写错误同时放大；先过白名单再赋值，拒绝项要有输出。

## 延伸
给部署工具扩展配置校验：白名单之外再叠加取值范围检查与默认值回填。

## 复现
TAG=latest scripts/run-example.sh shell L2-014-config-allowlist-load
