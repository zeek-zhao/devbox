<!-- coverage: pending -->

# L3-007-intrusive-list —— 从内嵌节点找回宿主对象

## 考点

- 把链表节点嵌入业务结构体，避免额外节点分配。
- 使用 `offsetof` 的 `container_of` 从节点指针恢复宿主结构体。

## 为什么这么写

链表只理解通用节点，遍历时通过成员偏移回到宿主对象，输出稳定的 ID 而不泄露地址。

## 易错点

- 结构体成员前可能存在 padding，不能假定节点在结构体开头。
- `container_of` 的成员名和节点类型必须匹配。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-007-intrusive-list
```
