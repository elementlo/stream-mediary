import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:stream_mediary/app.dart';

/// Captures a screenshot of the app's home page (the "downloads" tab).
///
/// Run via the driver so the image is written to disk:
///
/// ```bash
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/screenshot_test.dart \
///   -d <device-id> \
///   --dart-define=SCREENSHOT_PLATFORM=android
/// ```
///
/// The `SCREENSHOT_PLATFORM` define controls the output file name prefix
/// (e.g. `android-home.png`). It defaults to the host OS name.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture home page screenshot', (tester) async {
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

    // Let fonts, theme and the first frame settle.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await binding.takeScreenshot('home');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
