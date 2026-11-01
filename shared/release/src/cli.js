#!/usr/bin/env node
// 入口。参数解析 + 六条安全门的落点。
// ------------------------------------------------------------------
// 契约（REL-01 卡片按这个实现，不许放宽）：
//   默认 dry-run；--write 才落盘
//   工作树脏 -> 退出码 2，错误信息里说明「请先提交或 stash」
//   当前分支在 protectedBranches 里 -> 退出码 2，提示 --allow-branch
//   版本号文件只认 config.versionFiles 白名单，绝不推断
//   不做任何 push，不发起网络请求
//
// 支持的参数：
//   --write                 真正落盘（默认只预览）
//   --release-as <major|minor|patch|x.y.z>
//   --allow-branch <name>   允许在受保护分支上执行
//   --cwd <dir>             指定目标仓库
//   --help / --version
import { loadConfig } from './config.js';

export const EXIT_OK = 0;
export const EXIT_FAIL = 1;
export const EXIT_SAFETY = 2;

export function parseArgs(argv) {
  // TODO(REL-01)：实现参数解析，返回结构化选项
  throw new Error('未实现');
}

export async function main(argv = process.argv.slice(2)) {
  // TODO(REL-01)：串起 config -> commits -> bump -> plan -> (write)
  throw new Error('未实现');
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().then((code) => process.exit(code)).catch((err) => {
    console.error(err.message);
    process.exit(1);
  });
}
