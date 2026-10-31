// 按白名单读写版本号。只认 config.versionFiles 里显式列出的文件。
// ------------------------------------------------------------------
// kind 支持：
//   json  —— 读/写顶层或点号路径的字符串字段（如 "version" 或 "project.version"）
//   plain —— 整个文件就是一个版本号（如 VERSION）
//   toml  —— 只做**行级精确替换**，不引第三方 toml 库（避免为一个字段拉一棵依赖树）
//
// 写文件一律「写临时文件再 rename」，避免中途失败留下半截文件。
// ★ 任何不在白名单里的文件，一个字节都不许写。
import fs from 'node:fs';

export function readVersion(file) {
  // TODO(REL-01)
  throw new Error('未实现');
}

export function writeVersion(file, version) {
  // TODO(REL-01)
  throw new Error('未实现');
}

export function assertWritable(file, config) {
  // TODO(REL-01)：白名单校验，不在白名单里就抛错
  throw new Error('未实现');
}
