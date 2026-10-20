/// Screenshot demo mode.
///
/// Gated entirely by dart-defines so production builds carry no behavior
/// change (the constants fold at compile time and the branches tree-shake):
///
/// - `SCREENSHOT_DEMO=true` — seed a fake in-progress download task, force
///   the zh locale and skip network side effects (update check, board
///   prefetch) so the home page is presentation-ready.
/// - `SCREENSHOT_THEME=light|dark` — force the theme instead of following
///   the saved setting / system.
///
/// Used by `integration_test/screenshot_test.dart` (Android / iOS),
/// `tool/screenshot_desktop.sh` (macOS) and
/// `.github/workflows/windows-screenshot.yml` (Windows).
library;

import 'package:flutter/material.dart';

/// Whether screenshot demo mode is enabled.
const bool kScreenshotDemo = bool.fromEnvironment('SCREENSHOT_DEMO');

const String _kScreenshotTheme = String.fromEnvironment('SCREENSHOT_THEME');

/// The forced [ThemeMode] for screenshot captures, or null to follow the
/// user's settings.
ThemeMode? get screenshotThemeMode => switch (_kScreenshotTheme) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => null,
};
