// Central bilingual copy for the site. Keeping every user-facing string here
// means the two page variants stay in sync and translators have one file.

export const ui = {
  'zh-CN': {
    'nav.features': '功能',
    'nav.screenshots': '截图',
    'nav.download': '下载',
    'nav.extension': '浏览器扩展',
    'nav.whatsnew': '更新日志',
    'nav.faq': '常见问题',
    'nav.github': 'GitHub',
    'nav.lang': 'English',

    'hero.badge': '开源 · MIT 许可 · 全平台',
    'hero.title': 'Mediary',
    'hero.subtitle': '跨平台 M3U8 / HLS 媒体下载器',
    'hero.desc':
      '解析、下载、解密并合并流媒体分片，输出单个可播放的视频文件。支持 Android、iOS、Windows 与 macOS。',
    'hero.cta.download': '立即下载',
    'hero.cta.github': '查看源码',

    'features.title': '功能特性',
    'features.subtitle': '为流媒体下载而生的完整工具链',
    'features.hls.title': 'HLS 解析',
    'features.hls.desc':
      '粘贴 .m3u8 地址即可预览分片数量、总时长、加密状态与估算大小；master playlist 列出全部清晰度供选择。',
    'features.png.title': 'PNG 包装 HLS',
    'features.png.desc':
      '直接解析 roUd PNG 中的清单、分片与密钥，配合浏览器扩展一键唤起下载，无需本地代理。',
    'features.concurrent.title': '并发下载',
    'features.concurrent.desc':
      '两级调度：任务级并发 + 任务内分片并发，AIMD 自适应窗口随网络状况动态调整。',
    'features.aes.title': 'AES 解密',
    'features.aes.desc':
      '纯 Dart 流式 AES-128/192/256-CBC 解密，支持自定义请求头与用户指定的 KEY / IV 覆盖。',
    'features.merge.title': '智能合并',
    'features.merge.desc':
      '分片按序拼接为单个 .ts；检测到 ffmpeg 时无损 remux 为 .mp4，失败自动回退。',
    'features.resume.title': '断点续传',
    'features.resume.desc':
      '应用重启后自动恢复未完成任务，已完成分片不重复下载；分片级指数退避重试。',
    'features.player.title': '内置播放器',
    'features.player.desc':
      '应用内直接播放下载的 .ts / .mp4，完整控制条与桌面端键盘快捷键。',
    'features.history.title': '历史记录',
    'features.history.desc':
      '任务历史持久化，支持播放、重新下载、打开所在目录与删除。',

    'screenshots.title': '产品截图',
    'screenshots.subtitle': 'Material 3 设计，亮色 / 暗色 / 跟随系统',
    'screenshots.light': '亮色',
    'screenshots.dark': '暗色',
    'screenshots.toggle.aria': '切换截图主题',
    'screenshots.android': 'Android',
    'screenshots.ios': 'iOS',
    'screenshots.macos': 'macOS',
    'screenshots.windows': 'Windows',

    'download.title': '下载安装',
    'download.subtitle': '从 GitHub Releases 获取对应平台的安装包',
    'download.windows': 'Windows x64',
    'download.windows.note': '解压后运行 Mediary.exe',
    'download.macos': 'macOS',
    'download.macos.note': '内含 Mediary.app（Apple Silicon / Intel）',
    'download.android': 'Android',
    'download.android.note': 'ARM64 / ARMv7 APK',
    'download.ios': 'iOS',
    'download.ios.note': '无签名 .app.zip，需自行签名侧载',
    'download.releases': '全部版本',
    'download.unsigned':
      '桌面版未签名与公证，首次打开时系统可能提示安全警告。',

    'extension.title': '浏览器扩展',
    'extension.subtitle': '在视频网页上一键嗅探流地址，唤起 Mediary 下载',
    'extension.desc':
      '配套的 Chrome 扩展 Video Stream Link Detector 会在视频网页上自动检测 HLS / PNG 包装流入口。鼠标悬停视频即出现「视频链接」按钮，选中清晰度后一键通过 stream-mediary:// 深链唤起桌面 Mediary，并自动带上来源网页与浏览器 UA——无需手动复制地址，也无需本地代理。',
    'extension.f1.title': '自动检测',
    'extension.f1.desc':
      '通用、站点中立地识别 .m3u8 / HLS MIME / 直链视频，以及 roUd PNG 包装流，无需为每个网站写规则。',
    'extension.f2.title': '一键唤起',
    'extension.f2.desc':
      'macOS / Windows 上点击「Mediary 下载」直接拉起桌面应用并填好地址与请求头。',
    'extension.f3.title': '规格可选',
    'extension.f3.desc':
      '弹窗把每个清晰度 / 带宽列成卡片（含估算大小），选中后再复制或下载。',
    'extension.cta': '查看扩展仓库',
    'extension.note': '扩展为独立项目，安装与使用说明见其仓库主页。',

    'whatsnew.title': '最近更新',
    'whatsnew.subtitle': '各版本的新功能、改进与修复',
    'whatsnew.full': '查看完整更新日志',
    'whatsnew.added': '新增',
    'whatsnew.changed': '改进',
    'whatsnew.fixed': '修复',

    'faq.title': '常见问题',
    'faq.q1': 'Mediary 是免费的吗？',
    'faq.a1':
      '是。Mediary 基于 MIT 许可开源，所有功能完全免费，没有内购或广告。',
    'faq.q2': '需要安装 ffmpeg 吗？',
    'faq.a2':
      '不需要。ffmpeg 是可选的：检测到时合并结果会无损 remux 为 .mp4，未检测到则保留 .ts，功能不受影响。',
    'faq.q3': '支持 DRM 保护的内容吗？',
    'faq.a3':
      '不支持。Mediary 仅用于下载你拥有合法权利的内容，不提供绕过 DRM 的能力。',
    'faq.q4': '浏览器扩展是做什么的？',
    'faq.a4':
      '配套的 Chrome 扩展可在视频网页上自动嗅探 HLS / PNG 包装流入口，一键唤起桌面 Mediary 下载，免去手动复制地址。',
    'faq.q5': '下载的视频保存在哪里？',
    'faq.a5':
      '默认保存在应用的下载目录，可在设置中自定义。每个任务有独立文件夹，合并后输出单个视频文件。',

    'footer.tagline': '基于 Flutter 打造的跨平台 HLS 下载器。',
    'footer.links': '链接',
    'footer.resources': '资源',
    'footer.license': '许可',
    'footer.rights': '仅供个人、学习与合法用途。',
  },
  en: {
    'nav.features': 'Features',
    'nav.screenshots': 'Screenshots',
    'nav.download': 'Download',
    'nav.extension': 'Extension',
    'nav.whatsnew': "What's New",
    'nav.faq': 'FAQ',
    'nav.github': 'GitHub',
    'nav.lang': '简体中文',

    'hero.badge': 'Open source · MIT licensed · Cross-platform',
    'hero.title': 'Mediary',
    'hero.subtitle': 'Cross-platform M3U8 / HLS media downloader',
    'hero.desc':
      'Parse, download, decrypt and merge streaming segments into a single playable video. Available for Android, iOS, Windows and macOS.',
    'hero.cta.download': 'Download now',
    'hero.cta.github': 'View source',

    'features.title': 'Features',
    'features.subtitle': 'A complete toolchain built for stream downloading',
    'features.hls.title': 'HLS parsing',
    'features.hls.desc':
      'Paste an .m3u8 URL to preview segment count, duration, encryption and estimated size. Master playlists expose every quality variant.',
    'features.png.title': 'PNG-wrapped HLS',
    'features.png.desc':
      'Parses manifests, segments and keys inside roUd PNG containers, with one-click launch from the browser extension — no local proxy.',
    'features.concurrent.title': 'Concurrent downloads',
    'features.concurrent.desc':
      'Two-level scheduling: task-level plus per-task segment concurrency, with an AIMD adaptive window that reacts to network conditions.',
    'features.aes.title': 'AES decryption',
    'features.aes.desc':
      'Pure-Dart streaming AES-128/192/256-CBC decryption, with custom headers and user-supplied KEY / IV overrides.',
    'features.merge.title': 'Smart merging',
    'features.merge.desc':
      'Segments are concatenated into a single .ts; when ffmpeg is detected it is losslessly remuxed to .mp4, falling back on failure.',
    'features.resume.title': 'Resume & retry',
    'features.resume.desc':
      'Interrupted downloads resume automatically after restart; completed segments are never re-fetched. Per-segment backoff retry.',
    'features.player.title': 'Built-in player',
    'features.player.desc':
      'Play downloaded .ts / .mp4 files in-app with full controls and desktop keyboard shortcuts.',
    'features.history.title': 'History',
    'features.history.desc':
      'Persistent task history with replay, re-download, open-containing-folder and delete.',

    'screenshots.title': 'Screenshots',
    'screenshots.subtitle': 'Material 3 design — light, dark and system theme',
    'screenshots.light': 'Light',
    'screenshots.dark': 'Dark',
    'screenshots.toggle.aria': 'Toggle screenshot theme',
    'screenshots.android': 'Android',
    'screenshots.ios': 'iOS',
    'screenshots.macos': 'macOS',
    'screenshots.windows': 'Windows',

    'download.title': 'Download',
    'download.subtitle': 'Grab the installer for your platform from GitHub Releases',
    'download.windows': 'Windows x64',
    'download.windows.note': 'Extract and run Mediary.exe',
    'download.macos': 'macOS',
    'download.macos.note': 'Contains Mediary.app (Apple Silicon / Intel)',
    'download.android': 'Android',
    'download.android.note': 'ARM64 / ARMv7 APK',
    'download.ios': 'iOS',
    'download.ios.note': 'Unsigned .app.zip; sign it yourself to sideload',
    'download.releases': 'All releases',
    'download.unsigned':
      'Desktop builds are not signed or notarized; your OS may show a security warning on first launch.',

    'extension.title': 'Browser Extension',
    'extension.subtitle':
      'Sniff stream URLs on video pages and launch Mediary in one click',
    'extension.desc':
      'The companion Chrome extension, Video Stream Link Detector, automatically detects HLS / PNG-wrapped stream entries on video pages. Hover over a video to reveal a "Video Link" button, pick a quality, and launch desktop Mediary through the stream-mediary:// deep link — the source page and browser UA come along automatically. No manual URL copying, no local proxy.',
    'extension.f1.title': 'Automatic detection',
    'extension.f1.desc':
      'Generic, site-agnostic recognition of .m3u8 / HLS MIME / direct video files, plus roUd PNG-wrapped streams — no per-site rules needed.',
    'extension.f2.title': 'One-click launch',
    'extension.f2.desc':
      'On macOS / Windows, "Mediary Download" opens the desktop app with the URL and headers pre-filled.',
    'extension.f3.title': 'Selectable specs',
    'extension.f3.desc':
      'The popup lists every quality / bandwidth variant as a card with its estimated size; pick one, then copy or download.',
    'extension.cta': 'View extension repo',
    'extension.note':
      'The extension is a separate project; see its repository for install and usage instructions.',

    'whatsnew.title': "What's New",
    'whatsnew.subtitle': 'Features, improvements and fixes by release',
    'whatsnew.full': 'View full changelog',
    'whatsnew.added': 'New',
    'whatsnew.changed': 'Improved',
    'whatsnew.fixed': 'Fixed',

    'faq.title': 'FAQ',
    'faq.q1': 'Is Mediary free?',
    'faq.a1':
      'Yes. Mediary is open source under the MIT license — every feature is free, with no in-app purchases or ads.',
    'faq.q2': 'Do I need to install ffmpeg?',
    'faq.a2':
      'No. ffmpeg is optional: when detected, the merged output is losslessly remuxed to .mp4; otherwise the .ts is kept and nothing breaks.',
    'faq.q3': 'Is DRM-protected content supported?',
    'faq.a3':
      'No. Mediary is for downloading content you have the legal rights to, and provides no ability to bypass DRM.',
    'faq.q4': 'What does the browser extension do?',
    'faq.a4':
      'The companion Chrome extension sniffs HLS / PNG-wrapped stream entries on video pages and launches desktop Mediary in one click — no manual URL copying.',
    'faq.q5': 'Where are downloaded videos saved?',
    'faq.a5':
      'By default in the app download directory, customizable in Settings. Each task gets its own folder and merges into a single video file.',

    'footer.tagline': 'A cross-platform HLS downloader built with Flutter.',
    'footer.links': 'Links',
    'footer.resources': 'Resources',
    'footer.license': 'License',
    'footer.rights': 'For personal, educational and legitimate use only.',
  },
} as const;

export type Lang = keyof typeof ui;
export const defaultLang: Lang = 'zh-CN';

export function getLangFromUrl(url: URL): Lang {
  // On a GitHub Pages project site the pathname carries the repo base
  // (e.g. /stream-mediary/en/), so strip BASE_URL before reading the locale
  // segment — otherwise the base itself is mistaken for the language.
  const base = (import.meta.env.BASE_URL ?? '/').replace(/\/$/, '');
  const pathNoBase = url.pathname.replace(base, '') || '/';
  const [, lang] = pathNoBase.split('/');
  if (lang && lang in ui) return lang as Lang;
  return defaultLang;
}

/** Typed translation accessor. */
export function useTranslations(lang: Lang) {
  return function t(key: keyof (typeof ui)[typeof defaultLang]): string {
    return ui[lang][key] ?? ui[defaultLang][key];
  };
}

/** The other language, for the switcher and hreflang. */
export const altLang: Record<Lang, Lang> = {
  'zh-CN': 'en',
  en: 'zh-CN',
};
