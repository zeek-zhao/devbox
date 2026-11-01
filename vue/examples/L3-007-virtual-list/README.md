<!-- coverage: pending -->

# L3-007-virtual-list —— 一千条数据的十行窗口

## 考点

- 固定 200px 容器与 20px 行高，从 scrollTop 计算十行窗口。
- 一千条数据只生成窗口内 li，从真实 SSR HTML 统计数量与首尾下标。
- 验证顶部、中间、超过底部时的窗口钳制。

## 为什么这么写

SSR 无滚动事件，直接把三个确定性滚动位置作为 props，不模拟不存在的 DOM。
完整高度的占位层保留滚动空间，窗口绝对定位到 start × rowHeight。
本例只验证整行窗口，不引入 overscan 或可变行高；因此无须定时器。
数量来自渲染结果而不是 slice 长度，防止“算十行却渲染一千行”假通过。

## 易错点

- 容器不设固定高度，就没有可视区窗口的意义。
- 用 scrollTop 直接作为数组下标，中间窗口会错。
- 底部 start 不钳制，可能只渲染一行甚至空列表。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L3-007-virtual-list
```
