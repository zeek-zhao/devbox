# L4-003-abstract-factory

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-03：一个工厂接口成组创建一族相互配套的产品，切换工厂即切换整套实现。

可观察判据：两个工厂类各自返回配套的按钮与文本框，`family` 属性同族一致、跨族不同。

## 为什么这样写

代码位置：`main.py:34-57` 定义成组创建接口与两族工厂，`main.py:60-75` 检查配套关系。

`main.py` 的 `WidgetFactory` 声明两个创建方法；`LightFactory` 与 `DarkFactory`
分别返回自己的 `Button` 和 `TextBox` 子类，并非一个带分支参数的简单工厂。
`describe()` 中的两次创建与 `button.family == text_box.family` 行验证配套关系，
入口再比较两个工厂产出的族。若把暗色文本框换成亮色文本框，
`family: dark dark` 与第二行 `matched: True` 会变化；
若两个工厂都创建亮色族，`different families: True` 会变为 `False`。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-003-abstract-factory
```
