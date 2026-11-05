<!--
PR 描述请回答三件事：为什么改、怎么验的、影响谁。
「改了什么」由 diff 说明，不用重复。
spec v2 起新增四段（执行留痕 / UNVERIFIED / verifier 结论 / spec 版本），
规范见 docs/71-任务卡规范v2.md 与 docs/75-文档健康规范.md。
-->

## 动机

<!-- 现在的问题是什么？为什么必须改？ -->

## 改动范围

<!-- 涉及的轨道 / 目录。如果动了门禁文件（见 scripts/gate-files.txt），在这里单独说明并给出理由 -->

- [ ] 只改了与标题相关的文件
- [ ] 没有改动 `scripts/gate-files.txt` 里的门禁文件；若改动了，已在下方说明理由

## 验证

<!-- 贴真实命令与输出，不要写「本地测过了」 -->

```bash
# 单条用例
bash scripts/run-example.sh <轨道> <用例ID>

# 整门轨道
make examples LANG=<轨道> TAG=latest

# 格式化
bash scripts/fmt.sh --check --lang <轨道>
```

## 输出确定性

<!-- 新增或修改用例时必填：连跑两次是否完全一致？输出里有没有时间戳、随机数、容器 IP、耗时？ -->

- [ ] 同一用例连跑两次输出完全一致
- [ ] stdout 只放业务结果，错误信息走 stderr

## 执行留痕（spec v2）

<!-- 命令与退出码、files_changed；没跑过的一律写 UNVERIFIED，不许写「已验证」 -->

| 字段 | 值 |
|---|---|
| run_id / 会话 | |
| commands_run（命令 → 退出码） | |
| files_changed | |

## UNVERIFIED 项

<!-- 没跑过、没验到的判据逐条列出；本表为空才算全验 -->

- [ ] 无（若有，逐条列出：判据 → 原因 → 谁来补验）

## verifier 结论

<!-- 由独立 verifier 填写（见 docs/73 §6）；implementer 不自评 -->

- [ ] `pass` / [ ] `revise` / [ ] `escalate`
- 证据引用（报告章节 / 命令输出）：

## spec / 判据版本

<!-- 本 PR 依据的任务卡正文与规范版本；规范变更时注明 commit -->

| 项 | 值 |
|---|---|
| 任务卡 | # |
| 判据来源 | docs/71 · docs/75 |
| 规范版本（commit / 日期） | |

## 关联

<!-- 关闭的 Issue：Closes #123 -->
