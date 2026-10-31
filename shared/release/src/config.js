import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import defaultConfig from '../release.config.js';

export async function loadConfig(cwd) {
  const file = path.join(cwd, 'release.config.js');
  let override = {};
  if (fs.existsSync(file)) {
    const url = pathToFileURL(file);
    url.searchParams.set('release-config', String(fs.statSync(file).mtimeMs));
    const loaded = await import(url.href);
    override = loaded.default ?? loaded;
  }
  const cfg = {
    ...defaultConfig,
    ...override,
    types: override.types ?? defaultConfig.types,
    versionFiles: override.versionFiles ?? defaultConfig.versionFiles,
    protectedBranches: override.protectedBranches ?? defaultConfig.protectedBranches,
    cwd,
  };
  validateConfig(cfg);
  return cfg;
}

export function validateConfig(cfg) {
  if (!cfg || typeof cfg !== 'object' || Array.isArray(cfg)) {
    throw new Error('release.config.js 必须导出一个配置对象');
  }
  if (!Array.isArray(cfg.versionFiles)) {
    throw new Error('配置 versionFiles 必须是数组');
  }
  cfg.versionFiles.forEach((file, index) => {
    if (!file || typeof file !== 'object' || typeof file.path !== 'string' || !file.path.trim()) {
      throw new Error(`配置 versionFiles[${index}] 必须包含非空 path`);
    }
    if (!['json', 'plain', 'toml'].includes(file.kind)) {
      throw new Error(`配置 versionFiles[${index}].kind 必须是 json、plain 或 toml`);
    }
    if (file.kind !== 'plain' && (typeof file.key !== 'string' || !file.key.trim())) {
      throw new Error(`配置 versionFiles[${index}].key 必须是非空字符串`);
    }
  });
  if (!Array.isArray(cfg.types)) {
    throw new Error('配置 types 必须是数组');
  }
  cfg.types.forEach((item, index) => {
    if (!item || typeof item.type !== 'string' || !item.type.trim()) {
      throw new Error(`配置 types[${index}].type 必须是非空字符串`);
    }
    if (typeof item.section !== 'string' || !item.section.trim()) {
      throw new Error(`配置 types[${index}].section 必须是非空字符串`);
    }
  });
  if (!Array.isArray(cfg.protectedBranches) || cfg.protectedBranches.some((name) => typeof name !== 'string')) {
    throw new Error('配置 protectedBranches 必须是字符串数组');
  }
  return cfg;
}
