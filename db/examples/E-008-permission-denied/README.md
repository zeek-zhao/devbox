# E-008-permission-denied —— 权限拒绝（1044/1142）的归因与修复路径

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-008 权限拒绝的归因与修复），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「错误分类学」（`E-001-error-taxonomy`）主题的 db 轨落地：
权限类错误（1044 连库拒绝 / 1142 表级操作拒绝 / 1143 列级）是一类**不可重试、
修法在库外**的错误——修复动作是改授权或改调用方，重试只是刷日志。

## 现象

只读账号 `SELECT` 一切正常，`INSERT` 报 `1142`（command denied）；连库权限
都没有的账号在 **connect 阶段**就报 `1044`（access denied to database）。
把两类都当成「连接坏了」重试，或当成「数据库挂了」告警，方向全错。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-008-permission-denied
# 或单独跑断言：
bash db/examples/E-008-permission-denied/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：`select_ok rows=1` → `insert_denied err=1142
class=permission retryable=no` → `GRANT` 后 `grant_fixed insert_ok=1` →
`REVOKE` 后 `revoked err=1142 closed=yes` → 无库权限账号
`no_db_access err=1044 class=permission retryable=no`。

## 为什么这样处理

- 权限错误一律 `retryable=no`：授权状态不会因为重试改变，唯一的修复是
  `GRANT`（补权限）或改调用方（去掉越权操作）。
- 授权变更对**已存在连接**的下一条语句即生效（GRANT/REVOKE 直接改内存授权表）：
  修复不需要重启应用连接池，验证修复也不用重连。
- 表级（1142）与连库级（1044）分开归因：前者报「对这张表没有 INSERT」，
  后者在 connect 就抛——排障时一个查 `SHOW GRANTS`，一个查库级授权。

## 反例

- 对 1142 做退避重试——授权不变，重试一万次还是 1142。
- 用 root 账号跑业务「绕过」权限错误——错误被掩盖，最小权限形同虚设。
- 把 1044/1142 与 1045（口令错）混为一类——都是 access denied 文案，
  但 1045 是凭证、1044/1142 是授权，修法完全不同。

## 依赖服务

`mysql`

## 命名空间

`db_e_008_permission_denied`
