# L2-006-cargo-features


## 考点
对应 KP-RS-L2-06：在 manifest 声明 feature，并用同名 `cfg` 选择实现。
看到默认配置与启用 `diagnostics` 后分别输出不同模式，说明两种配置均可构建。

## 易错点
引用未启用配置中的专属符号会导致编译失败。
在 manifest 声明 feature，并用匹配的条件编译保护相关实现。

## 延伸
将可选诊断输出应用到索引构建与查询路径。
比较默认 feature 与显式 feature 对依赖及构建配置的影响。

## 复现
TAG=latest scripts/run-example.sh rust L2-006-cargo-features
