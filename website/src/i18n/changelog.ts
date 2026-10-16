// Bilingual release highlights shown in the "What's new" section.
//
// Kept as curated summaries rather than parsing CHANGELOG.md at build time:
// the changelog is English-only and its entries are far too verbose for a
// landing page. When cutting a new release, add its highlights here (both
// locales) — oldest entries can be dropped to keep the list short.

export type ChangeKind = 'added' | 'changed' | 'fixed';

export interface ReleaseEntry {
  version: string;
  date: string;
  changes: { kind: ChangeKind; text: string }[];
}

export const releases: Record<'zh-CN' | 'en', ReleaseEntry[]> = {
  'zh-CN': [
    {
      version: '0.3.0',
      date: '2026-10-15',
      changes: [
        {
          kind: 'added',
          text: '留言板支持发送 emoji 表情：内置 6 分类表情面板，移动端自动收起键盘、桌面端限宽居中，在光标处连续插入。',
        },
        {
          kind: 'changed',
          text: '全新「Soft Iris」低饱和紫配色：主色、语义色与启动图标整体焕新，下载中/合并中状态凭颜色即可区分。',
        },
        {
          kind: 'added',
          text: '上线官方网站（你正在看的这个）：中英双语，含功能介绍、截图、下载与常见问题。',
        },
        {
          kind: 'fixed',
          text: '修复卡片内列表项的水波纹反馈被卡片背景遮挡的问题。',
        },
      ],
    },
    {
      version: '0.2.2',
      date: '2026-10-09',
      changes: [
        {
          kind: 'fixed',
          text: 'Windows 托盘「退出」立即生效：主窗口即刻消失，不再卡顿约 2 秒；退出时不再触发大量取消事件导致界面假死。',
        },
      ],
    },
    {
      version: '0.2.1',
      date: '2026-10-09',
      changes: [
        {
          kind: 'fixed',
          text: 'Windows 应用内更新后不再残留命令行窗口，关闭该窗口也不会再误杀刚更新完的应用。',
        },
        {
          kind: 'fixed',
          text: '旧版本因磁盘满卡在「合并中」的下载任务，升级后启动时自动恢复，不再滞留列表且无法删除。',
        },
      ],
    },
    {
      version: '0.2.0',
      date: '2026-10-08',
      changes: [
        {
          kind: 'added',
          text: '磁盘满处理：下载或合并时空间不足会暂停并保留进度，列表显示「清理空间后继续」提示，腾出空间后可断点续传。',
        },
        {
          kind: 'added',
          text: 'ffmpeg 路径可在设置中手动指定；桌面端额外探测常见安装位置（Program Files、choco、scoop、winget）。',
        },
      ],
    },
  ],
  en: [
    {
      version: '0.3.0',
      date: '2026-10-15',
      changes: [
        {
          kind: 'added',
          text: 'Emoji picker on the message board: a built-in 6-category panel that inserts at the caret. The keyboard steps aside on mobile; the panel is width-capped on desktop.',
        },
        {
          kind: 'changed',
          text: 'New "Soft Iris" low-saturation purple palette across the UI, semantic colors and launcher icons; downloading vs merging stays distinguishable by color alone.',
        },
        {
          kind: 'added',
          text: 'Launched the official website (the one you are reading): bilingual, with features, screenshots, downloads and FAQ.',
        },
        {
          kind: 'fixed',
          text: 'Ink splashes on list rows inside cards are no longer hidden by the card background.',
        },
      ],
    },
    {
      version: '0.2.2',
      date: '2026-10-09',
      changes: [
        {
          kind: 'fixed',
          text: 'Windows tray "Quit" is instant: the window disappears immediately instead of freezing for ~2s, and shutdown no longer floods the UI with cancellation events.',
        },
      ],
    },
    {
      version: '0.2.1',
      date: '2026-10-09',
      changes: [
        {
          kind: 'fixed',
          text: 'The Windows in-app update no longer leaves a lingering console window, and closing it no longer kills the freshly updated app.',
        },
        {
          kind: 'fixed',
          text: 'Downloads stuck in "merging" by older builds (disk-full hang) are now recovered on startup instead of lingering with no way to delete them.',
        },
      ],
    },
    {
      version: '0.2.0',
      date: '2026-10-08',
      changes: [
        {
          kind: 'added',
          text: 'Disk-full handling: tasks pause and keep progress when space runs out, with a "free up space then resume" banner and resume-from-where-it-left-off.',
        },
        {
          kind: 'added',
          text: 'The ffmpeg path can be set manually in Settings; desktop detection also probes common install locations (Program Files, choco, scoop, winget).',
        },
      ],
    },
  ],
};
