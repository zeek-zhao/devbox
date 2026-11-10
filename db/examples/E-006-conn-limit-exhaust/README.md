# E-006-conn-limit-exhaust —— 连接数耗尽（容量类错误）的归因与让路

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-006 连接数耗尽的归因与让路），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「优雅降级与容量保护」（`E-013-graceful-degradation`）主题的
db 轨落地：连接数被服务端配额（`max_user_connections`，错误码 1226）拒绝是容量类
错误——处理动作是「让路（释放租约）再重试」或「快速失败」，唯独不是原地空转重试。

## 现象

连接用满服务端给该用户的配额后，新申请报 `1226`（exceeded 'max_user_connections'）。
它和 E-001 的 2003（连不上）看起来都是「connect 抛异常」，但类别不同：2003 是环境
类、重试可能自愈；1226 是容量类、自己不释放容量重试一万次也是 1226。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-006-conn-limit-exhaust
# 或单独跑断言：
bash db/examples/E-006-conn-limit-exhaust/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：两个租约成功，第 3 个 `lease_exceeded err=1226
class=capacity action=shed`，释放一个租约后 `retry lease ok=yes`，
租约日志 `log_rows=2`（初始 1 行 + 让路后新增 1 行）。

## 为什么这样处理

- 归因挂在错误码上：1040/1226 归为容量类，动作是 shed（让路/限流），不是 retry。
- 1226 的「自愈」只能来自**自己释放容量**：先 `close()` 一个租约再重试，
  重试才有意义；直接重试只会把配额错误变成重试风暴。
- 用 `MAX_USER_CONNECTIONS 2` 的专用账号复现，而不是打满全局
  `max_connections`：容量故障要能在自己的命名空间里复现，不许砸共享实例。

## 反例

- 捕获 1226 后 `time.sleep` 再重试——配额是自己占的，睡多久都还是 1226。
- 把 1226 当连接失败（2003）交给「环境类重试」——类别错了，动作全错。
- 用打满全局 `max_connections` 的方式复现——用例自己把共享栈打挂，殃及所有用例。

## 依赖服务

`mysql`

## 命名空间

`db_e_006_conn_limit_exhaust`
