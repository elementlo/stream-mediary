#!/usr/bin/env node
// Validates CHANGELOG.md against the bilingual format the website parser
// (src/i18n/changelog.ts) relies on. Run via `npm run check:changelog`;
// the website CI runs it before building so a malformed changelog fails the
// deploy instead of silently rendering half-translated notes.
//
// Format contract (keep in sync with changelog.ts):
//   ## [x.y.z] - YYYY-MM-DD          release heading
//   ### 新增 / Added                 kind heading (Added|Changed|Fixed + zh)
//   - 中文一行                        bullet, Chinese, no indent
//     English on the next line       English continuation, indented 2+ spaces
//
// Exit code 0 = valid, 1 = violations (each printed with its line number).

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const changelogPath = resolve(here, '../../CHANGELOG.md');

const KIND_WORDS = ['added', 'changed', 'fixed', '新增', '改进', '变更', '修复'];
const RELEASE_RE = /^##\s+\[([^\]]+)\]\s*-\s*(.+?)\s*$/;
const VERSION_RE = /^\d+\.\d+\.\d+$/;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const KIND_RE = /^###\s+(.+?)\s*$/;
const BULLET_RE = /^-\s+(.+?)\s*$/;
const CONT_RE = /^\s{2,}(\S.*?)\s*$/;

/** Compares dotted versions; returns >0 if a is newer than b. */
function cmpVersion(a, b) {
  const pa = a.split('.').map(Number);
  const pb = b.split('.').map(Number);
  for (let i = 0; i < 3; i++) {
    if ((pa[i] ?? 0) !== (pb[i] ?? 0)) return (pa[i] ?? 0) - (pb[i] ?? 0);
  }
  return 0;
}

function validate(markdown) {
  const errors = [];
  const lines = markdown.split('\n');

  let inComment = false;
  let lastVersion = null;
  let releaseCount = 0;
  // Tracks the bullet awaiting its English continuation line.
  let pendingBulletLine = -1;
  let pendingHasEn = false;
  let inRelease = false;
  let sawKindInRelease = false;
  let sawBulletInKind = false;
  let kindLine = -1;

  const flushBullet = () => {
    if (pendingBulletLine >= 0 && !pendingHasEn) {
      errors.push(
        `第 ${pendingBulletLine} 行：该条目缺少缩进的英文行（中文行下需有 2+ 空格缩进的英文翻译）。`,
      );
    }
    pendingBulletLine = -1;
    pendingHasEn = false;
  };

  for (let i = 0; i < lines.length; i++) {
    const lineNo = i + 1;
    const line = lines[i].replace(/\r$/, '');

    // Skip the HTML format-guidance comment block.
    if (inComment) {
      if (line.includes('-->')) inComment = false;
      continue;
    }
    if (line.trimStart().startsWith('<!--')) {
      if (!line.includes('-->')) inComment = true;
      continue;
    }

    const relMatch = line.match(RELEASE_RE);
    if (relMatch) {
      flushBullet();
      if (inRelease && !sawKindInRelease) {
        errors.push(`上一个版本缺少 ### 分类小节（Added/Changed/Fixed）。`);
      }
      if (sawKindInRelease && !sawBulletInKind) {
        errors.push(`第 ${kindLine} 行：分类小节下没有任何条目。`);
      }
      inRelease = true;
      sawKindInRelease = false;
      sawBulletInKind = false;
      releaseCount++;

      const [, version, date] = relMatch;
      if (!VERSION_RE.test(version.trim())) {
        errors.push(`第 ${lineNo} 行：版本号 "${version}" 不符合 x.y.z。`);
      } else if (lastVersion && cmpVersion(version.trim(), lastVersion) >= 0) {
        errors.push(
          `第 ${lineNo} 行：版本 ${version} 未比上一个 ${lastVersion} 更旧（须按新→旧排列）。`,
        );
      }
      lastVersion = version.trim();
      if (!DATE_RE.test(date.trim())) {
        errors.push(`第 ${lineNo} 行：日期 "${date}" 不符合 YYYY-MM-DD。`);
      }
      continue;
    }

    const kindMatch = line.match(KIND_RE);
    if (kindMatch) {
      flushBullet();
      if (sawKindInRelease && !sawBulletInKind) {
        errors.push(`第 ${kindLine} 行：分类小节下没有任何条目。`);
      }
      const heading = kindMatch[1].toLowerCase();
      if (!KIND_WORDS.some((w) => heading.includes(w))) {
        errors.push(
          `第 ${lineNo} 行：分类标题 "${kindMatch[1]}" 未包含 Added/Changed/Fixed（或 新增/改进/修复）。`,
        );
      }
      sawKindInRelease = true;
      sawBulletInKind = false;
      kindLine = lineNo;
      continue;
    }

    if (!inRelease) continue;

    const bulletMatch = line.match(BULLET_RE);
    if (bulletMatch) {
      flushBullet();
      if (!sawKindInRelease) {
        errors.push(`第 ${lineNo} 行：条目出现在任何 ### 分类小节之前。`);
      }
      pendingBulletLine = lineNo;
      pendingHasEn = false;
      sawBulletInKind = true;
      continue;
    }

    const contMatch = line.match(CONT_RE);
    if (contMatch && pendingBulletLine >= 0) {
      pendingHasEn = true;
      continue;
    }

    // A non-blank, non-continuation line ends the pending bullet.
    if (line.trim() !== '' && pendingBulletLine >= 0) {
      flushBullet();
    }
  }
  flushBullet();
  if (inRelease && !sawKindInRelease) {
    errors.push(`最后一个版本缺少 ### 分类小节。`);
  }
  if (sawKindInRelease && !sawBulletInKind) {
    errors.push(`第 ${kindLine} 行：分类小节下没有任何条目。`);
  }
  if (releaseCount === 0) {
    errors.push('未解析到任何版本（## [x.y.z] - 日期）。');
  }

  return { errors, releaseCount };
}

let markdown;
try {
  markdown = readFileSync(changelogPath, 'utf-8');
} catch (e) {
  console.error(`✗ 无法读取 CHANGELOG.md：${e.message}`);
  process.exit(1);
}

const { errors, releaseCount } = validate(markdown);
if (errors.length > 0) {
  console.error(`✗ CHANGELOG.md 格式校验失败（${errors.length} 处）：`);
  for (const e of errors) console.error(`  - ${e}`);
  console.error(
    '\n约定见 CHANGELOG.md 顶部注释与 AGENTS.md「CHANGELOG 双语约定」。',
  );
  process.exit(1);
}
console.log(`✓ CHANGELOG.md 格式校验通过（${releaseCount} 个版本）。`);
