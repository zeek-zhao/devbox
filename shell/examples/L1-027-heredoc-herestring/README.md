# L1-027-heredoc-herestring


## 考点
对应 KP-SH-L1-27：比较 here-document 的变量展开、引用分隔符保留原文及 here-string 输入。
看到未引用文档输出 `service`、引用文档保留 `$name`、here-string 读到单行，即掌握此点。

## 易错点
未引用 here-document 分隔符会启用参数、命令和算术展开，模板文本可能被改写。
需要保留模板原文时写成 `<<'EOF'`，明确禁止展开。

## 延伸
用引用分隔符将多行配置模板原样传给命令，再显式替换需要变化的字段。
将 here-string 用于给读取命令传一行内容，并区分其与多行 here-document。

## 复现
TAG=latest scripts/run-example.sh shell L1-027-heredoc-herestring
