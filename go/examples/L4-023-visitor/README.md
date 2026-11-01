# L4-023-visitor

<!-- coverage: exempt 输出只有同构 Word 记录的平面 slice，没有异构节点树及双分派操作；序列化由 Result 自身承担，不需要访问者跨多种节点类型扩展操作 -->

## 考点

对应 KP-GO-L4-23：把作用于对象结构的操作从元素类中分离，新增操作不改元素。

可观察判据：元素接口含 `Accept(v Visitor)`，两个访问者对两个元素输出固定文本。

## 为什么这样写

`main.go` 第 5–26 行定义元素、访问者接口，File 的 `Accept` 调用
`v.VisitFile(f)`，Folder 的 `Accept` 调用 `v.VisitFolder(f)`，没有类型 switch。
第 28–41 行两个访问者分别实现命名和指标操作，操作不放进元素中。
第 45–55 行以两个接口切片遍历：先按元素动态类型分派 `Accept`，
再按访问者动态类型分派 `VisitFile`/`VisitFolder`，真正执行四种组合。
若拆掉 File 的转发，`name file: main.go` 和 `metrics file: main.go bytes=42`
两行会消失，实际累加的 `total bytes: 42` 会变成 0。
增加第三种访问操作只需实现访问者，不必修改现有元素。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh go L4-023-visitor
```
