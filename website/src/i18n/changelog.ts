// Build-time parser for the root CHANGELOG.md.
//
// The changelog is the single source of truth for release notes, written in a
// concise bilingual format (Chinese first line, indented English second line).
// This module parses it at build time so the website's "What's New" section
// always matches the shipped changelog — no second copy to keep in sync.
//
// Expected format (see CHANGELOG.md):
//   ## [0.3.0] - 2026-10-15
//   ### 新增 / Added
//   - 中文一行
//     English on the next (indented) line

// Import the changelog as a raw string at build time. Vite resolves this
// relative to the source file and inlines the content, so it works in the
// bundled prerender output (unlike fs.readFileSync + import.meta.url, which
// would resolve against dist/ at runtime). Type declared in src/vite-env.d.ts.
import changelogMd from '../../../CHANGELOG.md?raw';

export type ChangeKind = 'added' | 'changed' | 'fixed';

export interface Change {
  kind: ChangeKind;
  zh: string;
  en: string;
}

export interface Release {
  version: string;
  date: string;
  changes: Change[];
}

/** Map a bilingual kind heading to a canonical kind. */
function kindFromHeading(heading: string): ChangeKind | null {
  const h = heading.toLowerCase();
  if (h.includes('added') || h.includes('新增')) return 'added';
  if (h.includes('changed') || h.includes('改进') || h.includes('变更')) {
    return 'changed';
  }
  if (h.includes('fixed') || h.includes('修复')) return 'fixed';
  return null;
}

/**
 * Parses the changelog markdown into structured releases.
 *
 * Tolerant by design: unknown headings are skipped, bullets without an
 * English continuation fall back to the Chinese text, and the HTML format
 * comment at the top is ignored.
 */
export function parseChangelog(markdown: string): Release[] {
  const releases: Release[] = [];
  let current: Release | null = null;
  let currentKind: ChangeKind | null = null;
  // The bullet being accumulated (its English line may follow).
  let pending: Change | null = null;
  // True while inside the HTML format-guidance comment at the top.
  let inComment = false;

  const flushPending = () => {
    if (pending && current) current.changes.push(pending);
    pending = null;
  };

  for (const rawLine of markdown.split('\n')) {
    const line = rawLine.replace(/\r$/, '');

    // Skip the format-guidance HTML comment block (may span lines).
    if (inComment) {
      if (line.includes('-->')) inComment = false;
      continue;
    }
    if (line.trimStart().startsWith('<!--')) {
      if (!line.includes('-->')) inComment = true;
      continue;
    }

    // Release heading: ## [0.3.0] - 2026-10-15
    const relMatch = line.match(/^##\s+\[([^\]]+)\]\s*-\s*(.+?)\s*$/);
    if (relMatch) {
      flushPending();
      current = {
        version: relMatch[1].trim(),
        date: relMatch[2].trim(),
        changes: [],
      };
      releases.push(current);
      currentKind = null;
      continue;
    }

    // Kind heading: ### 新增 / Added
    const kindMatch = line.match(/^###\s+(.+?)\s*$/);
    if (kindMatch) {
      flushPending();
      currentKind = kindFromHeading(kindMatch[1]);
      continue;
    }

    if (!current) continue;

    // Bullet start: "- text" (no leading whitespace).
    const bulletMatch = line.match(/^-\s+(.+?)\s*$/);
    if (bulletMatch && currentKind) {
      flushPending();
      pending = {
        kind: currentKind,
        zh: bulletMatch[1].trim(),
        en: '',
      };
      continue;
    }

    // Indented continuation line: the English translation of `pending`.
    const contMatch = line.match(/^\s{2,}(\S.*?)\s*$/);
    if (contMatch && pending && !pending.en) {
      pending.en = contMatch[1].trim();
      continue;
    }
  }
  flushPending();

  // Fall back to Chinese when an English line is missing.
  for (const rel of releases) {
    for (const c of rel.changes) {
      if (!c.en) c.en = c.zh;
    }
  }
  return releases;
}

/** Parses the repository-root CHANGELOG.md (inlined at build time). */
export function loadReleases(): Release[] {
  return parseChangelog(changelogMd);
}

/** Releases for one locale, newest first (changelog order is already newest-first). */
export function releasesFor(lang: 'zh-CN' | 'en', all: Release[]): {
  version: string;
  date: string;
  changes: { kind: ChangeKind; text: string }[];
}[] {
  return all.map((rel) => ({
    version: rel.version,
    date: rel.date,
    changes: rel.changes.map((c) => ({
      kind: c.kind,
      text: lang === 'en' ? c.en : c.zh,
    })),
  }));
}
