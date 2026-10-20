import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:stream_mediary/app.dart';

/// Captures a home-page screenshot with a live demo download in flight.
///
/// The app must be built with these dart-defines:
/// - `SCREENSHOT_DEMO=true` — seeds a fake in-progress task, forces the zh
///   locale and skips network side effects (update check, board prefetch).
/// - `SCREENSHOT_THEME=light|dark` — forces the theme. Read synchronously by
///   `ThemeModeNotifier.build`, so no settings I/O is awaited in-test (which
///   would hang under the fake-async test zone).
///
/// NOTE: `takeScreenshot()` hangs on some emulator GPUs (the surface
/// conversion never completes). The reliable path that actually produces the
/// committed shots is OS-level capture — see `tool/screenshot_mobile.sh`
/// (adb screencap / simctl io screenshot). This test is kept as the
/// integration_test reference path.
///
/// One run produces one shot; run twice (light, then dark):
///
/// ```bash
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/screenshot_test.dart \
///   -d <device-id> \
///   --dart-define=SCREENSHOT_DEMO=true \
///   --dart-define=SCREENSHOT_THEME=light \
///   --dart-define=SCREENSHOT_PLATFORM=android
/// ```
///
/// Output: `docs/screenshots/<platform>-home-<theme>.png`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const theme = String.fromEnvironment('SCREENSHOT_THEME', defaultValue: 'light');

  testWidgets('capture home page screenshot ($theme)', (tester) async {
    // Give the app a stable, presentation-friendly surface size.
    tester.view.physicalSize = const Size(1170, 2532); // iPhone-ish portrait
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: StreamMediaryApp()),
    );

    // Required on Android/iOS before takeScreenshot(); must be awaited
    // inside the test, after the first pump (see SDK extended_test example).
    await binding.convertFlutterSurfaceToImage();

    // Let fonts, theme, the demo-task seed and the first frames settle.
    // No pumpAndSettle: the segment bar pulses forever while downloading.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));

    await binding.takeScreenshot('home-$theme');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
