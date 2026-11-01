coverage: exempt 焦点顺序属于浏览器可达性范畴；Todo 项目是无打包器 SSR 形态，没有真实焦点树可接入。

# L3-021-focus-order

## 考点

纯函数过滤不可聚焦项并为可达元素分配确定的 roving tabindex 顺序。

## 易错点

`tabindex="-1"` 仍可通过脚本聚焦；禁用项应先从顺序中剔除。

## 延伸

真实焦点行为还需在浏览器中验证键盘顺序、焦点可见性和辅助技术语义。

## 复现

```bash
TAG=local scripts/run-example.sh vue L3-021-focus-order
```
