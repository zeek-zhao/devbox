import fs from 'node:fs';
import path from 'node:path';

function jsonTarget(data, key) {
  const parts = key.split('.');
  let parent = data;
  for (const part of parts.slice(0, -1)) {
    if (!parent || typeof parent !== 'object' || !(part in parent)) {
      throw new Error(`JSON 版本字段不存在：${key}`);
    }
    parent = parent[part];
  }
  const property = parts.at(-1);
  if (!parent || typeof parent !== 'object' || !(property in parent)) {
    throw new Error(`JSON 版本字段不存在：${key}`);
  }
  return { parent, property };
}

function tomlTarget(content, key) {
  const parts = key.split('.');
  const property = parts.pop();
  const wantedSection = parts.join('.');
  let section = '';
  const lines = content.split(/(?<=\n)/);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const header = /^\s*\[([^\]]+)\]\s*(?:#.*)?(?:\r?\n)?$/.exec(line);
    if (header) {
      section = header[1].trim();
      continue;
    }
    if (section !== wantedSection) continue;
    const match = new RegExp(`^(\\s*${property.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\s*=\\s*")([^"]+)(".*(?:\\r?\\n)?)$`).exec(line);
    if (match) return { lines, index, match };
  }
  throw new Error(`TOML 版本字段不存在：[${wantedSection || '根'}] ${property}`);
}

export function readVersion(file) {
  const content = fs.readFileSync(file.path, 'utf8');
  if (file.kind === 'plain') return content.trim();
  if (file.kind === 'json') {
    const parsed = JSON.parse(content);
    const { parent, property } = jsonTarget(parsed, file.key);
    if (typeof parent[property] !== 'string') throw new Error(`JSON 版本字段必须是字符串：${file.key}`);
    return parent[property];
  }
  if (file.kind === 'toml') {
    const target = tomlTarget(content, file.key);
    return target.match[2];
  }
  throw new Error(`不支持的版本文件类型：${file.kind}`);
}

export function writeVersion(file, version) {
  const content = fs.readFileSync(file.path, 'utf8');
  let updated;
  if (file.kind === 'plain') {
    updated = `${version}${content.endsWith('\n') ? '\n' : ''}`;
  } else if (file.kind === 'json') {
    const parsed = JSON.parse(content);
    const { parent, property } = jsonTarget(parsed, file.key);
    if (typeof parent[property] !== 'string') throw new Error(`JSON 版本字段必须是字符串：${file.key}`);
    parent[property] = version;
    const indent = content.match(/^[ \t]+(?=["\w])/m)?.[0] ?? 2;
    updated = `${JSON.stringify(parsed, null, indent)}${content.endsWith('\n') ? '\n' : ''}`;
  } else if (file.kind === 'toml') {
    const target = tomlTarget(content, file.key);
    target.lines[target.index] = `${target.match[1]}${version}${target.match[3]}`;
    updated = target.lines.join('');
  } else {
    throw new Error(`不支持的版本文件类型：${file.kind}`);
  }
  const temporary = `${file.path}.tmp`;
  try {
    fs.writeFileSync(temporary, updated, { encoding: 'utf8', flag: 'wx' });
    fs.renameSync(temporary, file.path);
  } catch (error) {
    if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
    throw error;
  }
}

export function assertWritable(file, config) {
  const cwd = config.cwd ?? process.cwd();
  const target = path.resolve(cwd, file.path);
  const allowed = config.versionFiles.some((item) => path.resolve(cwd, item.path) === target);
  if (!allowed) {
    throw new Error(`拒绝写入白名单外的版本文件：${file.path}；请将其显式加入 release.config.js 的 versionFiles`);
  }
}
