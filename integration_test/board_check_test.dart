import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:stream_mediary/app.dart';

/// Cross-platform smoke check for the message board.
///
/// Navigates to the board tab, waits for the real Waline server to respond,
/// and asserts the composer plus at least one loaded comment render.
///
/// Run on any device/simulator/desktop:
///
/// ```bash
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/board_check_test.dart -d DEVICE_ID
/// ```
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('message board loads and renders comments', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: StreamMediaryApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Navigate to the board tab (bottom bar on phones, rail on desktop).
    await tester.tap(find.text('留言板'));
    await tester.pump();

    // Wait for the network load to resolve (fixed pumps: the initial
    // spinner animates forever, so pumpAndSettle cannot be used).
    var hasComment = false;
    for (var i = 0; i < 15 && !hasComment; i++) {
      await tester.pump(const Duration(seconds: 1));
      hasComment = find.text('probe').evaluate().isNotEmpty ||
          find.text('积极').evaluate().isNotEmpty;
    }
    expect(hasComment, isTrue, reason: 'no comment rendered from server');

    // The compose FAB is present and opens the sheet.
    expect(find.text('发布'), findsOneWidget);
    await tester.tap(find.text('发布'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('说点什么…'), findsOneWidget,
        reason: 'composer sheet did not open');
    // The sheet is modal (no back button); dismiss via its scrim.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('说点什么…'), findsNothing,
        reason: 'composer sheet did not dismiss');

    // Surface capture is mobile-only; desktop verification stops at the
    // assertions above.
    try {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await binding.takeScreenshot('board');
    } catch (_) {
      // Not supported on this platform; assertions already passed.
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
