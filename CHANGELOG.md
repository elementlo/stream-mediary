# Changelog

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
- Task context menu: right-click a download task on macOS/Windows, or long-press on Android/iOS, to copy the download link. Tasks imported from the browser extension also offer "copy source page", which copies the web page the stream came from.
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

- Reuse the running Windows downloader when the browser extension opens another video link.
- Show the configured default download directory on the parse preview and keep the parsed playlist when choosing a different directory.
- Refresh available disk space for a changed directory without refetching the media playlist.

### Companion extension

- Open captured signed PNG stream URLs directly when available, avoiding a second request to the HLS entry endpoint.
- Show in-page video controls on mouse hover and close their menu when clicking outside it.

## [0.0.8] - 2026-09-25

### Added

- Download HLS playlists, segments, initialization sections, and keys wrapped in PNG `roUd` chunks without a local proxy.
- Open the new download screen from the Chrome extension on macOS and Windows with the source URL, Referer, and User-Agent filled in.
- Save technical errors and stack traces to a rotating local `mediary.log`; show concise, actionable messages in the UI.
- Publish an unsigned iOS app archive for developers who can sign and sideload it.

### Fixed

- Resolve relative redirect locations before resolving nested playlist and segment URLs, including signed CDN query parameters.
- Prevent a missing macOS deep-link bridge from stopping the app before its UI appears.
- Keep raw parser, network, player, merge, and message-board exceptions out of user-facing error messages.

## [0.0.7] - 2026-09-24

- Improved the visibility of the off-state switch thumb in high-contrast themes.
