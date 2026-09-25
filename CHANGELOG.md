# Changelog

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
