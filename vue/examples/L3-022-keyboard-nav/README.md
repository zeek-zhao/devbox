coverage: exempt Todo 页面使用原生表单、链接和按钮导航，没有自定义复合控件；roving tabindex 会替代而非补充其原生键盘行为。

# L3-022-keyboard-nav

## 考点

纯状态机为左右方向键、Home、End 和空集合计算下一个 roving tabindex 索引。

## 易错点

循环移动时需正确处理负数取模；长度为零时不能产生有效索引。

## 延伸

自定义列表框、标签页等复合控件可复用状态机，但仍需浏览器可访问性测试。

## 复现

```bash
TAG=local scripts/run-example.sh vue L3-022-keyboard-nav
```
