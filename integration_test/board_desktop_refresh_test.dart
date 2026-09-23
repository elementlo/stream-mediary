import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:stream_mediary/app.dart';

/// Desktop-layout check for the message board refresh button.
///
/// Uses a wide viewport so the app renders the desktop shell (header refresh
/// button instead of pull-to-refresh), then exercises the refresh path that
/// the phone-sized board_check_test never reaches.
///
/// ```bash
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/board_desktop_refresh_test.dart -d macos
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop board refresh button reloads the list', (tester) async {
    // Wide desktop viewport -> NavigationRail + header actions.
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: StreamMediaryApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Open the board from the rail.
    await tester.tap(find.text('留言板'));
    await tester.pump();

    // Wait for the first load to render a comment.
    var hasComment = false;
    for (var i = 0; i < 15 && !hasComment; i++) {
      await tester.pump(const Duration(seconds: 1));
      hasComment = find.text('probe').evaluate().isNotEmpty ||
          find.text('积极').evaluate().isNotEmpty;
    }
    expect(hasComment, isTrue, reason: 'no comment rendered from server');

    // The desktop header must expose a refresh button (tooltip 刷新).
    final refreshBtn = find.byTooltip('刷新');
    expect(refreshBtn, findsOneWidget,
        reason: 'desktop refresh button missing');

    // Tap refresh. The header button shows an in-button spinner while the
    // request is in flight; assert it appears, then completes (disappears).
    // This catches BOTH a hung refresh (spinner never clears) and an error.
    await tester.tap(refreshBtn);
    await tester.pump();

    bool buttonSpinnerShowing() => find
        .descendant(
          of: find.byTooltip('刷新'),
          matching: find.byType(CircularProgressIndicator),
        )
        .evaluate()
        .isNotEmpty;

    // Wait for the in-flight spinner to appear (request started).
    var started = false;
    for (var i = 0; i < 5 && !started; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      started = buttonSpinnerShowing();
    }

    // Then wait for it to clear (request finished), up to ~30s to tolerate a
    // cold serverless backend.
    var finished = false;
    for (var i = 0; i < 30 && !finished; i++) {
      await tester.pump(const Duration(seconds: 1));
      finished = !buttonSpinnerShowing();
    }

    // Surface the exact error text if a banner appeared, so CI logs explain
    // the failure instead of just asserting.
    final errorTexts = find
        .byWidgetPredicate((w) => w is Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .where((t) =>
            t.contains('timed out') ||
            t.contains('refused') ||
            t.contains('reset') ||
            t.contains('server returned') ||
            t.contains('network') ||
            t.contains('Socket') ||
            t.contains('Handshake') ||
            t.contains('certificate'))
        .toList();
    // ignore: avoid_print
    print('REFRESH started=$started finished=$finished errors=$errorTexts');

    expect(finished, isTrue,
        reason: 'refresh hung: in-button spinner never cleared');
    expect(find.text('重试'), findsNothing,
        reason: 'refresh produced an error banner: $errorTexts');
    expect(
        find.text('probe').evaluate().isNotEmpty ||
            find.text('积极').evaluate().isNotEmpty,
        isTrue,
        reason: 'list empty after refresh');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
