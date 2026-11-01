# L1-023-with-modifiers

## 考点

`withModifiers` applies prevent/stop behavior to a handler using a plain event object; once-only invocation is a separate listener policy.

## 易错点

`once` is not a `withModifiers` modifier. Treating it as one conflates event side effects with listener registration semantics.

## 延伸

Template modifiers compile to handler wrappers, while component event `.once` is represented by a one-shot listener.

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-023-with-modifiers
```
