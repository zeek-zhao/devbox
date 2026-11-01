# L1-013-vfor-key

## 考点

分别 SSR 渲染有 key 与无 key 的列表，比较静态 HTML 输出。

## 易错点

SSR 输出相同并不能说明 key 多余。key 用于客户端更新时稳定识别列表节点，无 key 时 Vue 可能按位置复用。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-013-vfor-key
```
