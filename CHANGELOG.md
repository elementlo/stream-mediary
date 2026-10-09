# Changelog

## [0.2.2] - 2026-10-09

### Fixed

- Windows tray "Quit" now makes the main window disappear immediately instead of leaving it frozen on screen for up to ~2 seconds. The window is hidden before shutdown starts, and the teardown that stops in-flight downloads is bounded to 400 ms (was 2 s) — a hard exit is already crash-safe, since downloads use `.part` files with atomic renames and sqlite runs in WAL mode.
- Quitting no longer floods the UI with cancellation events. The task list unsubscribes from the database and engine event feeds before the engine is disposed, so cancelling every in-flight download cannot trigger a rebuild storm on a window that is going away (the other cause of the apparent freeze).
- `DownloadEngine.dispose()` no longer awaits closing its broadcast event stream, which could block on listeners that were mid-handler during shutdown.

## [0.2.1] - 2026-10-09

### Fixed

- Windows in-app update no longer leaves a lingering command-prompt window after installing. The installer batch used to delete itself with a bare `del`, which made cmd fail to read the next line ("找不到批处理文件") and keep the minimized console open; because the relaunched app was a child of that console, closing the window also quit the app. The script now ends the batch context cleanly before deleting itself.
- A download stuck in the "merging" state by an older build (which had no disk-full detection and hung the merge on a full disk) is now recovered on startup instead of lingering in the downloads list with no way to cancel or delete it. Such stale records are cold-resumed: the merge retries using the already-downloaded segments, and if the disk is still full the task pauses into a recoverable, actionable state.

## [0.2.0] - 2026-10-08

### Added

- Disk-full handling: when a download or merge runs out of disk space, the task now pauses (keeping its progress) instead of failing with a generic error. The downloads list shows a "disk full — free up space then resume" banner, a system notification fires for background downloads, and the merge pre-flights available space so it stops before writing a truncated file. Resuming after freeing space continues from where it left off.
- ffmpeg path can now be set manually in Settings (Browse or type a path, validated before saving). Desktop ffmpeg detection also probes common Windows install locations (Program Files, chocolatey, scoop, winget) in addition to PATH.

### Fixed

- Windows tray "Quit" no longer leaves the main window hanging for several seconds after the tray icon disappears. In-flight downloads and timers are stopped first and the process exits promptly.
- macOS: the App Sandbox is disabled so the app can run an ffmpeg binary outside its bundle (previously ffmpeg detection always failed on macOS).

## [0.1.1] - 2026-10-01

### Fixed

- In-app update: a verification failure after the download reached 100% was misreported as "download failed, check your network". It now shows an accurate "file verification failed" message, tolerates a connection teardown error only when all bytes arrived, and retries once from scratch before giving up.
- Windows update install no longer flashes an endless series of command-prompt windows. The installer batch now runs in a single minimized console that its child commands share.
- Windows tray "Quit" no longer hangs for a while before exiting; the quit is deferred out of the native menu's modal loop.

## [0.1.0] - 2026-10-01

### Added

- In-app language switch: Settings → Language offers System / 中文 / English. The whole UI re-renders in the chosen language immediately, without a restart, and the choice persists across restarts.

### Fixed

- Windows tray icon: the right-click context menu (with "Quit") now opens reliably, including while the main window is hidden. Upgraded the tray implementation so the menu is shown natively instead of through a path that silently failed on a hidden window.
- Windows Chinese text no longer renders in a serif fallback (SimSun) that clashed with the sans-serif UI; Chinese now uses the platform-native sans-serif (Microsoft YaHei).
- Download cards: the speed readout is flush right again instead of stranded mid-row when an ETA is shown.

## [0.0.15] - 2026-10-01

### Added

- Update traffic (release checks and package downloads) now honors the configured download proxy, matching the download engine. The proxy applies immediately on save and persists across restarts.

### Fixed

- Windows in-app update no longer hangs on "installing" with a lingering console window. The installer script is now launched detached so it does not inherit the app's stdout/stderr pipes (which previously deadlocked against the script waiting for the app to exit), and no console window is allocated.

## [0.0.14] - 2026-09-30

### Added

- Self-healing merge: corrupt or vanished segments are skipped instead of failing the whole merge (TS stays playable with a small gap), and the MP4 remux retries with relaxed error detection. The result card reports how many segments were skipped.
- Merge result card: "Open containing folder" and "Delete segments" actions (with confirmation), on all platforms.
- Download task context menu (right-click on desktop, long-press on mobile) adds "Open containing directory", resolving the task folder for both finished and in-progress downloads.

### Fixed

- Windows/macOS no longer show the "MP4 conversion is not supported on mobile" hint when the real reason is a missing or failing ffmpeg; each fallback reason now has its own message.
- Desktop title-row actions (Batch import, Clear completed, Pause all) are flush right instead of stranded mid-row; flow-page primary buttons are right-aligned on desktop per the design spec.
- Desktop button height raised from 32px to 36px for better visual balance.

## [0.0.13] - 2026-09-29

### Added

- Segment concurrency is now configurable in Settings (2–32, default raised from 8 to 16), so downloads can better saturate fast connections.
- Adaptive concurrency (AIMD): the download window starts at the configured maximum, grows additively while segments succeed, and halves on congestion signals (timeouts, connection errors, HTTP 429/5xx) — throughput stays high on healthy sources while backing off quickly on slow or rate-limiting ones.

### Changed

- AES decryption and PNG `roUd` unwrapping (zlib) now run on worker isolates instead of the main isolate. Previously these CPU-bound steps blocked the event loop and serialized what was supposed to be concurrent downloading — the main cause of unstable speeds.
- Retry backoff shortened from 1s/3s/9s to 0.3s/1s/3s so transient blips cost milliseconds instead of seconds.
- Permanent HTTP errors (400/401/403/404/410) now fail immediately instead of burning three retry rounds, surfacing the real problem (e.g. an expired link) faster.

## [0.0.12] - 2026-09-29

### Added

- Download proxy: configure a local HTTP proxy (host + port) in Settings and all download traffic — playlists, segments and AES keys — is routed through it. Leaving it empty restores direct connections. The setting takes effect immediately on save (in-flight segments finish on the old connection, the next segment uses the new one) and persists across restarts.
- Task context menu: right-click a download task on macOS/Windows, or long-press on Android/iOS, to copy the download link. Tasks that carry a source web page also offer "copy source page", which copies the web page the stream came from.
- Download cards now show the total file size next to the downloaded amount ("123 MB / 456 MB"). Byte-range playlists report an exact total up front; other playlists show a running estimate, and nothing is shown when the size cannot be determined.

### Fixed

- Default titles no longer collide for image-disguised playlists with generic names (`index.jpg`, `master.jpeg`, …): JPG/JPEG/WebP/GIF disguises are now recognized like PNG, and generic names fall back to a unique `host-timestamp` title instead of every download sharing the same folder name.

## [0.0.11] - 2026-09-28

### Fixed

- Downloads no longer freeze when a server stalls mid-transfer: segment, key and playlist requests now carry connect (30s) and idle-receive (60s) timeouts, so a hung connection fails and retries instead of blocking its scheduler slot forever.
- Pausing a task now also cancels an in-flight AES key fetch (it previously used a token that pause never cancelled), so resume starts cleanly instead of waiting on a dead connection.

## [0.0.10] - 2026-09-28

### Added

- In-app update check: the app looks for new GitHub releases at startup (once per version) and from Settings → About, shows the changelog in a dialog, downloads the platform installer with resume support and SHA-256 verification, then hands off to the system installer (Android), reveals the new app in Finder (macOS), or replaces the install directory and relaunches (Windows).
- Closing the main window on Windows and macOS now hides it instead of quitting, so downloads keep running in the background. Windows shows a tray icon with "show" and "quit" actions; macOS keeps the app in the Dock and clicking it reopens the window.

### Fixed

- Pausing or retrying a PNG-disguised download no longer fails on expired signed URLs: the engine re-parses the source and refreshes playlist, segment and key URLs while reusing already-downloaded segments. "Redownload" also re-parses the source instead of replaying the stale snapshot.
- Pausing a task no longer resets its progress to zero in the UI or the database; progress is persisted periodically so it also survives an app kill mid-download.
- Disguised sources whose URLs carry no meaningful name (e.g. `.../cdn/master.png`) now get unique default titles (`host-timestamp`) instead of all sharing the same folder name.

## [0.0.9] - 2026-09-26

### Fixed

- Reuse the running Windows downloader when a `stream-mediary://` link opens another video.
- Show the configured default download directory on the parse preview and keep the parsed playlist when choosing a different directory.
- Refresh available disk space for a changed directory without refetching the media playlist.

## [0.0.8] - 2026-09-25

### Added

- Download HLS playlists, segments, initialization sections, and keys wrapped in PNG `roUd` chunks without a local proxy.
- Open the new download screen from a `stream-mediary://` link on macOS and Windows with the source URL, Referer, and User-Agent filled in.
- Save technical errors and stack traces to a rotating local `mediary.log`; show concise, actionable messages in the UI.
- Publish an unsigned iOS app archive for developers who can sign and sideload it.

### Fixed

- Resolve relative redirect locations before resolving nested playlist and segment URLs, including signed CDN query parameters.
- Prevent a missing macOS deep-link bridge from stopping the app before its UI appears.
- Keep raw parser, network, player, merge, and message-board exceptions out of user-facing error messages.

## [0.0.7] - 2026-09-24

- Improved the visibility of the off-state switch thumb in high-contrast themes.
