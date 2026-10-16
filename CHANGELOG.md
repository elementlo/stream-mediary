# 更新日志 / Changelog

精简的双语更新日志。官网「最近更新」模块在构建时自动解析本文件。
Concise bilingual changelog. The website's "What's New" section parses this file at build time.

<!-- 格式 / Format:
  ## [版本 / version] - 日期 / date
  ### 新增 / Added   (或 Changed / Fixed)
  - 中文一行
    English on the next (indented) line
每条第一行为中文，缩进的第二行为英文。分类标题需含 Added/Changed/Fixed 之一。
First line of each bullet is Chinese, the indented second line is English.
Kind headings must contain one of Added/Changed/Fixed. -->

## [0.3.0] - 2026-10-15

### 新增 / Added

- 留言板新增 emoji 表情面板（6 分类，光标处插入）。
  Emoji picker on the message board (6 categories, inserts at the caret).
- 上线官方网站：中英双语，含功能、截图、下载与更新日志。
  Launched the official website: bilingual, with features, screenshots, downloads and changelog.

### 改进 / Changed

- 全新「Soft Iris」低饱和紫配色，覆盖主色、语义色与启动图标。
  New "Soft Iris" low-saturation purple palette across primary, semantic colors and launcher icons.

### 修复 / Fixed

- 修复卡片内列表项水波纹被卡片背景遮挡。
  Fixed ink splashes on list rows inside cards being hidden by the card background.

## [0.2.2] - 2026-10-09

### 修复 / Fixed

- Windows 托盘「退出」立即生效，不再卡顿约 2 秒。
  Windows tray "Quit" is now instant instead of freezing for ~2 seconds.
- 退出时不再因大量取消事件导致界面假死。
  Quitting no longer floods the UI with cancellation events that appeared to freeze it.

## [0.2.1] - 2026-10-09

### 修复 / Fixed

- Windows 更新后不再残留命令行窗口，关闭它也不会误杀应用。
  Windows update no longer leaves a lingering console window; closing it no longer kills the app.
- 旧版本因磁盘满卡在「合并中」的任务，升级后启动时自动恢复。
  Tasks stuck in "merging" from older builds (disk-full hang) are recovered on startup after upgrading.

## [0.2.0] - 2026-10-08

### 新增 / Added

- 磁盘满处理：空间不足时暂停并保留进度，清理后可断点续传。
  Disk-full handling: tasks pause and keep progress when space runs out, resuming after you free space.
- ffmpeg 路径可在设置中手动指定，并探测常见安装位置。
  The ffmpeg path can be set manually in Settings, with detection of common install locations.

### 修复 / Fixed

- Windows 托盘「退出」不再让主窗口滞留数秒。
  Windows tray "Quit" no longer leaves the main window hanging for seconds.
- macOS 关闭 App Sandbox，使应用可调用 bundle 外的 ffmpeg。
  macOS App Sandbox disabled so the app can run an ffmpeg binary outside its bundle.

## [0.1.1] - 2026-10-01

### 修复 / Fixed

- 更新下载校验失败时给出准确提示，并在必要时整体重试一次。
  Update verification failures now show an accurate message and retry once from scratch.
- Windows 更新安装不再连续闪现多个命令行窗口。
  Windows update install no longer flashes a series of console windows.
- Windows 托盘「退出」不再延迟。
  Windows tray "Quit" no longer hangs before exiting.

## [0.1.0] - 2026-10-01

### 新增 / Added

- 应用内语言切换（跟随系统 / 中文 / English），即时生效并持久化。
  In-app language switch (System / 中文 / English), applied instantly and persisted.

### 修复 / Fixed

- Windows 托盘右键菜单在主窗口隐藏时也能可靠弹出。
  The Windows tray context menu opens reliably even while the main window is hidden.
- Windows 中文改用平台原生无衬线字体（微软雅黑）。
  Chinese text on Windows now uses the native sans-serif (Microsoft YaHei).
- 下载卡片速度显示重新右对齐。
  Download card speed readout is flush right again.

## [0.0.15] - 2026-10-01

### 新增 / Added

- 更新检查与下载也走配置的代理。
  Update checks and downloads now honor the configured proxy.

### 修复 / Fixed

- Windows 更新不再卡在「安装中」并残留控制台窗口。
  Windows update no longer hangs on "installing" with a lingering console window.

## [0.0.14] - 2026-09-30

### 新增 / Added

- 自愈合并：损坏/丢失分片自动跳过，MP4 remux 失败时放宽重试。
  Self-healing merge: corrupt/vanished segments are skipped and MP4 remux retries with relaxed detection.
- 合并结果卡片支持「打开所在目录」「删除分片」。
  Merge result card adds "Open containing folder" and "Delete segments".
- 任务右键/长按菜单新增「打开所在目录」。
  Task context menu adds "Open containing directory".

### 修复 / Fixed

- ffmpeg 缺失/失败时给出对应提示，不再误报「移动端不支持」。
  Missing/failing ffmpeg now shows its own message instead of the wrong "mobile" hint.
- 桌面端标题栏操作按钮右对齐，按钮高度提升至 36px。
  Desktop title-row actions are flush right; button height raised to 36px.

## [0.0.13] - 2026-09-29

### 新增 / Added

- 分片并发可在设置中配置（2–32，默认 16）。
  Segment concurrency is configurable in Settings (2–32, default 16).
- AIMD 自适应并发：成功加性增、拥塞乘性减。
  Adaptive concurrency (AIMD): additive increase on success, multiplicative decrease on congestion.

### 改进 / Changed

- AES 解密与 PNG roUd 解包移至 worker isolate，不再阻塞主线程。
  AES decryption and PNG roUd unwrapping moved to worker isolates, no longer blocking the main thread.
- 重试退避缩短为 0.3s/1s/3s；永久错误（4xx）立即失败。
  Retry backoff shortened to 0.3s/1s/3s; permanent errors (4xx) fail immediately.

## [0.0.12] - 2026-09-29

### 新增 / Added

- 下载代理：设置本地 HTTP 代理后所有下载流量经其转发。
  Download proxy: route all download traffic through a local HTTP proxy.
- 任务菜单支持复制下载链接与来源网页。
  Task menu can copy the download link and source web page.
- 下载卡片显示总大小（「已下载 / 总计」）。
  Download cards show total size ("downloaded / total").

### 修复 / Fixed

- 图片伪装且通用名的播放列表不再产生重名标题。
  Image-disguised playlists with generic names no longer collide on title.

## [0.0.11] - 2026-09-28

### 修复 / Fixed

- 服务器中途卡住时不再冻结：请求带连接/接收超时。
  Downloads no longer freeze on a stalled server: requests carry connect/receive timeouts.
- 暂停任务会同时取消进行中的密钥请求。
  Pausing also cancels an in-flight AES key fetch.

## [0.0.10] - 2026-09-28

### 新增 / Added

- 应用内更新：检查 GitHub 新版本、下载校验并安装。
  In-app update: check GitHub releases, download with verification, and install.
- Windows/macOS 关闭主窗口改为隐藏，下载在后台继续。
  Closing the main window on Windows/macOS hides it so downloads keep running.

### 修复 / Fixed

- 暂停/重试 PNG 伪装下载时自动刷新过期签名链接。
  Pausing/retrying PNG-disguised downloads refreshes expired signed URLs.
- 暂停不再把进度重置为零，进度定期持久化。
  Pausing no longer resets progress to zero; progress is persisted periodically.

## [0.0.9] - 2026-09-26

### 修复 / Fixed

- stream-mediary:// 链接复用正在运行的 Windows 下载器。
  A stream-mediary:// link reuses the running Windows downloader.
- 解析预览显示默认下载目录，切换目录保留已解析列表。
  Parse preview shows the default download dir and keeps the playlist when changing it.

## [0.0.8] - 2026-09-25

### 新增 / Added

- 支持下载 PNG roUd 包装的 HLS（清单/分片/密钥），无需本地代理。
  Download HLS playlists, segments and keys wrapped in PNG roUd chunks, no local proxy.
- macOS/Windows 通过 stream-mediary:// 链接打开新建下载并填充来源信息。
  Open the new-download screen from a stream-mediary:// link with source info filled in.
- 技术错误写入本地滚动日志，界面只显示简洁可操作信息。
  Technical errors go to a rotating local log; the UI shows concise, actionable messages.

### 修复 / Fixed

- 先解析相对重定向再解析嵌套地址（含签名 CDN 参数）。
  Resolve relative redirects before nested playlist/segment URLs, including signed CDN params.

## [0.0.7] - 2026-09-24

### 修复 / Fixed

- 提升高对比主题下关闭态开关滑块的可见性。
  Improved the off-state switch thumb visibility in high-contrast themes.
