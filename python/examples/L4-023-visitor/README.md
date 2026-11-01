# L4-023-visitor

<!-- coverage: exempt 本项目报表树仅需统一 render 操作，未对多个稳定节点类型执行独立导出、审计或分析遍历；加入 accept 与双分派会复制已有组件渲染而没有第二种访问业务 -->

## 考点

对应 KP-PY-L4-23：把作用于对象结构的操作从元素类中分离，新增操作不改元素。

可观察判据：元素 `accept` 访问者，四种组合输出固定文本。

## 为什么这样写

`NumberNode.accept/TextNode.accept` 的返回行各自调用 `visit_number/visit_text`，
先由元素选择访问方法，再由访问者类型选择具体操作，构成双分派。
Python 不靠同名函数重载，使用两个显式访问方法，也不使用 `isinstance` 分支。
`RenderVisitor/MeasureVisitor` 分离渲染与度量，新增操作只需新增访问者，无需改节点。
`main()` 将两种访问者分别应用到同一组两种节点，四行均取自 `accept()` 返回值；
去掉访问者转发，输出会成为 `None`；将数字节点错接到文本方法，第一行标签会改变且度量调用失败。

## 怎么跑

TAG=latest bash scripts/run-example.sh python L4-023-visitor
