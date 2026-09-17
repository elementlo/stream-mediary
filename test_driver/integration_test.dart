import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Integration-test driver that persists screenshots taken by
/// `integration_test/screenshot_test.dart` to `docs/screenshots/`.
///
/// The output file name is `<platform>-<name>.png`, where `<platform>` comes
/// from the `SCREENSHOT_PLATFORM` dart-define (defaults to `shot`) and `<name>`
/// is the label passed to `binding.takeScreenshot(name)`.
///
/// Example:
/// ```bash
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/screenshot_test.dart \
///   -d <device-id> \
///   --dart-define=SCREENSHOT_PLATFORM=android
/// ```
Future<void> main() async {
  // Prefer the SCREENSHOT_PLATFORM environment variable (propagates to this
  // driver process); fall back to a dart-define, then to `shot`.
  final platform = Platform.environment['SCREENSHOT_PLATFORM'] ??
      const String.fromEnvironment(
        'SCREENSHOT_PLATFORM',
        defaultValue: 'shot',
      );

  final outDir = Directory('docs/screenshots');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? _]) async {
      final file = File('${outDir.path}/$platform-$name.png');
      file.writeAsBytesSync(bytes);
      // ignore: avoid_print
      print('Saved screenshot -> ${file.path}');
      return true;
    },
  );
}
