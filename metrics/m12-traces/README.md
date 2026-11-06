# metrics/m12-traces（M12 结构化执行留痕）

> 口径真本：[docs/80-M12度量规范](../../docs/80-M12度量规范.md)（#275）§2。本目录一 run 一文件，
> 文件名即 `run_id`（`<run-id>.json`）。schema 与 M11 verifier 的 `metrics/m11-traces/<run-id>.json`
> 同构（[docs/73](../../docs/73-M11并发执行计划.md) §6），在其五要素之上补
> `rubric_version`、`classification`、`reviewed_at`。

## 最小 schema

| 字段 | 类型 | 说明 |
|---|---|---|
| `spec_version` | string | 任务卡规范版本，如 `v2`（docs/71） |
| `rubric_version` | string | verifier rubric 版本号（docs/80 §5），如 `m12-rubric-1` |
| `model` | string | 执行模型标识；不可得写 `UNVERIFIED` |
| `session_id` | string | 会话标识（provider usage 对账键）；不可得写 `UNVERIFIED` |
| `run_id` | string | 运行标识，等于文件名去 `.json` |
| `head_sha` | string | 40 位 commit sha |
| `commands` | array of object | `{"cmd": string, "exit_code": number}`，只录真跑过的命令 |
| `assertions` | array of string | 逐条对应验收判据的证据行 |
| `classification` | string | `pass` / `fail` / `revise` / `escalate` / `UNVERIFIED` |
| `unverified` | array of string | `UNVERIFIED` 项的字段名与原因，无则空数组 |
| `owner` | string | `名字 <邮箱>`（docs/75 §1） |
| `reviewed_at` | string | `YYYY-MM-DD`；未复核写 `UNVERIFIED` |

## 示例（占位值登记时以真实值替换）

```json
{
  "spec_version": "v2",
  "rubric_version": "m12-rubric-1",
  "model": "<model-id>",
  "session_id": "<session-id>",
  "run_id": "m12-20261107-g8-replay",
  "head_sha": "<40-char-sha>",
  "commands": [
    { "cmd": "bash scripts/check-docs.sh", "exit_code": 0 },
    { "cmd": "bash scripts/check-version-truth.sh", "exit_code": 0 }
  ],
  "assertions": [
    "git diff --check 退出码 0",
    "check-docs.sh 汇总：N 条文档命令全部通过"
  ],
  "classification": "pass",
  "unverified": ["cost per accepted card（usage 数据源未接入）"],
  "owner": "zeek.zhao <zeek.zhao@foxmail.com>",
  "reviewed_at": "2026-11-07"
}
```

## 目录规则

1. **一 run 一文件**：`<run-id>.json`；同一卡多轮 run 各自成文件，成本按卡累计（docs/80 M-4）；
2. **只录真实值**：没跑过的一律写 `UNVERIFIED`，不许写「已验证」；拿不到的数据不填 0、不估算、不抄旧值（docs/80 §6）；
3. **不带凭证与私有信息**：run id、commit sha、公开命令可以留；token、账号、内网地址不许进本目录；
4. **`owner` 与 `reviewed_at` 必填**：缺省按 docs/75 §4 归维护者；`reviewed_at` 只在真复核过时更新；
5. **golden set 回放也落盘**：docs/80 §4 的 8 例每例回放后各落一条 JSON，`run_id` 建议带样例编号便于对账。
