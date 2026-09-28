# Changelog

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
