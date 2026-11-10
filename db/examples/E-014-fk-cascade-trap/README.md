# E-014-fk-cascade-trap —— 外键级联：1451 拒绝是护栏，CASCADE 是静默丢失通道

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-014 外键级联的拒绝与静默丢失），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「错误可观测性」（`E-013-error-observability`）主题的 db 轨落地：
同一次「删父行」，RESTRICT 外键把它变成显式错误（1451），CASCADE 把它变成
**零输出、零日志的静默数据丢失**——错误处理视角下，后者比前者危险一个量级。

## 现象

客户 1 挂着两张 RESTRICT 订单：直接删客户报 `1451`（row is referenced）；
显式两步（同事务先归档并删子行、再删父行）才删得掉。客户 2 挂着两张
CASCADE 发票：同一句 DELETE「成功」了，两张发票无声消失——
没有错误码、没有警告、没有回滚机会。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-014-fk-cascade-trap
# 或单独跑断言：
bash db/examples/E-014-fk-cascade-trap/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：`delete_parent err=1451 class=foreign_key
action=handle_children` → `explicit_two_step orders_left=0
customer_gone=yes` → `cascade_delete invoices_before=2 invoices_after=0
silent_loss=yes` → `customers_left=0`。

## 为什么这样处理

- 1451 是**护栏**：捕获后的处理动作是 handle_children（先处理子行），
  而不是绕过约束——E-002 已把 1452/1451 的方向归因讲清，这里进一步讲
  「拒绝删除」本身是数据库在替你保住引用完整性。
- CASCADE 必须是有记录的设计决定：它把「删父连带删子」变成一句 DML 的
  隐式副作用，排障时子行消失无迹可循；真要用，删父前业务层先留痕。
- 显式两步放在**同一个事务**里：归档与删除要么都发生要么都不发生，
  拆开就是「子行删了、父行没删成」的另一种半套状态。

## 反例

- 捕获 1451 后关掉外键检查（`FOREIGN_KEY_CHECKS=0`）硬删——护栏被拆，
  孤儿行落地，下一个查询开始悄悄错。
- 把 1451 当性能问题、「干脆全改成 CASCADE」——错误消失了，
  数据丢失通道打开了。
- 在应用层手写「先删子再删父」却不放同一事务——中途失败产生真孤儿。

## 依赖服务

`mysql`

## 命名空间

`db_e_014_fk_cascade_trap`
