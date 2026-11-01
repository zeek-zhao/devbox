# L1-040-default-trait

## 考点
对应 KP-RS-L1-40：Default 与结构体更新语法。未指定字段从默认值补齐，显示显式字段覆盖默认值

## 易错点
用 `..Default::default()` 补字段时，如果把它放在结构体更新表达式里，就不能再访问被移动出去的非 `Copy` 默认字段。只覆盖确实需要的字段并让默认值补齐其余项；若要复用原配置，应先借用或显式克隆需要保留的部分。

## 延伸
项目的 `src/lib.rs` 中 `CliOptions` 由 `parse_args` 显式填充操作、路径和 worker 数，没有用 `Default` 掩盖必需配置。配置默认值需要明确区分“用户未提供”和“有效空值”时，省略字段的写法才适合引入。

## 复现
TAG=latest scripts/run-example.sh rust L1-040-default-trait
