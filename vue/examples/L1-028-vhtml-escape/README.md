# L1-028-vhtml-escape

## 考点

SSR 转义插值文本，但 `innerHTML`（对应 `v-html`）插入原始标记。

## 易错点

原始 HTML 不会自动消毒；把不可信输入交给 `v-html` 会绕过文本转义，造成 XSS 风险。

## 延伸

优先使用文本插值；只有经过可信白名单清理的富文本才应进入 HTML 注入边界。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-028-vhtml-escape
```
