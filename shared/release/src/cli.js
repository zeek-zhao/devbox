#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { loadConfig } from './config.js';
import { readCommits } from './commits.js';
import { compareVersions } from './bump.js';
import { isClean, currentBranch, lastTag, git, commitAll, createTag } from './git.js';
import { buildPlan, formatPlan } from './plan.js';
import { readVersion, writeVersion, assertWritable } from './version-file.js';

export const EXIT_OK = 0;
export const EXIT_FAIL = 1;
export const EXIT_SAFETY = 2;

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const RELEASE_AS_RE = /^(major|minor|patch|\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)$/;

function validDate(value) {
  return DATE_RE.test(value) && !Number.isNaN(Date.parse(`${value}T00:00:00Z`))
    && new Date(`${value}T00:00:00Z`).toISOString().slice(0, 10) === value;
}

export function parseArgs(argv) {
  const options = { write: false, releaseAs: undefined, allowBranches: [], cwd: process.cwd(), date: undefined };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--write') options.write = true;
    else if (arg === '--help') options.help = true;
    else if (arg === '--version') options.version = true;
    else if (['--release-as', '--allow-branch', '--cwd', '--date'].includes(arg)) {
      const value = argv[++i];
      if (!value || value.startsWith('--')) throw new Error(`${arg} 需要一个值`);
      if (arg === '--release-as') {
        if (!RELEASE_AS_RE.test(value)) throw new Error(`无效的 --release-as：${value}`);
        if (!['major', 'minor', 'patch'].includes(value)) compareVersions(value, value);
        options.releaseAs = value;
      } else if (arg === '--allow-branch') options.allowBranches.push(value);
      else if (arg === '--cwd') options.cwd = path.resolve(value);
      else {
        if (!validDate(value)) {
          throw new Error(`无效的 --date：${value}，格式应为 YYYY-MM-DD`);
        }
        options.date = value;
      }
    } else throw new Error(`未知参数：${arg}`);
  }
  return options;
}

function detectRepoUrl(cwd) {
  try {
    const raw = git(['config', '--get', 'remote.origin.url'], cwd);
    const ssh = /^git@([^:]+):(.+)$/.exec(raw);
    const url = ssh ? `https://${ssh[1]}/${ssh[2]}` : raw.replace(/\.git$/, '');
    return url.replace(/\.git$/, '');
  } catch (error) {
    if (error.status === 1) return '';
    throw error;
  }
}

function writeTextAtomic(filePath, content) {
  const temporary = `${filePath}.tmp`;
  try {
    fs.writeFileSync(temporary, content, { encoding: 'utf8', flag: 'wx' });
    fs.renameSync(temporary, filePath);
  } catch (error) {
    if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
    throw error;
  }
}

export async function main(argv = process.argv.slice(2)) {
  let options;
  try {
    options = parseArgs(argv);
    if (options.help) {
      console.log('用法：zeek-release [--write] [--release-as <major|minor|patch|x.y.z>] [--allow-branch <name>] [--cwd <dir>] [--date YYYY-MM-DD]');
      return EXIT_OK;
    }
    if (options.version) {
      const packagePath = fileURLToPath(new URL('../package.json', import.meta.url));
      console.log(JSON.parse(fs.readFileSync(packagePath, 'utf8')).version);
      return EXIT_OK;
    }

    const cwd = options.cwd;
    const config = await loadConfig(cwd);
    if (!isClean(cwd)) {
      console.error('工作树有未提交改动；请先提交或 stash 后再运行。');
      return EXIT_SAFETY;
    }
    const branch = currentBranch(cwd);
    if (config.protectedBranches.includes(branch) && !options.allowBranches.includes(branch)) {
      console.error(`当前分支 ${branch} 受保护；如确认要继续，请显式传入 --allow-branch ${branch}。`);
      return EXIT_SAFETY;
    }
    const tag = lastTag(cwd, config.tagPrefix ?? 'v');
    const commits = readCommits({ cwd, from: tag, to: 'HEAD' });
    if (commits.skippedCount) console.log(`已跳过 ${commits.skippedCount} 个非 Conventional Commit。`);
    if (!commits.length) {
      console.log('没有可发布的提交。');
      return EXIT_OK;
    }
    if (!config.versionFiles.length) throw new Error('配置 versionFiles 为空，无法安全确定项目版本');
    const versionFile = config.versionFiles[0];
    const currentVersion = readVersion({
      ...versionFile,
      path: path.resolve(cwd, versionFile.path),
    });
    const releaseDate = options.date ?? process.env.RELEASE_DATE ?? git(['log', '-1', '--format=%cs'], cwd);
    if (!validDate(releaseDate)) throw new Error('RELEASE_DATE 或 --date 必须是有效的 YYYY-MM-DD 日期');
    const plan = buildPlan({
      config,
      commits,
      currentVersion,
      releaseAs: options.releaseAs,
      date: releaseDate,
      repoUrl: detectRepoUrl(cwd),
      previousTag: tag,
    });
    console.log(formatPlan(plan));
    if (!options.write) {
      console.log('预览模式：未修改文件。使用 --write 执行。');
      return EXIT_OK;
    }
    for (const file of config.versionFiles) assertWritable(file, config);
    if (git(['tag', '--list', plan.tag], cwd) === plan.tag) {
      throw new Error(`Tag ${plan.tag} 已存在；请先调整版本号或处理现有 tag`);
    }
    for (const file of plan.files) {
      const spec = config.versionFiles.find((item) => item.path === file.path);
      writeVersion({ ...spec, path: path.resolve(cwd, file.path) }, file.to);
    }
    const changelogPath = path.resolve(cwd, config.changelogPath);
    writeTextAtomic(changelogPath, plan.changelog);
    const message = (config.releaseCommitMessage ?? 'chore(release): {version}')
      .replaceAll('{version}', plan.nextVersion);
    commitAll(cwd, message);
    createTag(cwd, plan.tag, message);
    console.log(`已创建 release commit 和 tag ${plan.tag}；不会自动 push。`);
    return EXIT_OK;
  } catch (error) {
    console.error(error.message);
    return EXIT_FAIL;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  main().then((code) => process.exit(code));
}
