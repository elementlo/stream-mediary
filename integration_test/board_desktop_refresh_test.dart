import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:stream_mediary/app.dart';
import 'package:stream_mediary/data/remote/waline_client.dart';

/// Desktop-layout check for the message board refresh button.
///
/// Uses a wide viewport so the app renders the desktop shell (header refresh
/// button instead of pull-to-refresh). Proves refresh actually re-fetches by
/// posting a unique marker comment via the API first, then asserting it
/// appears only after the button is tapped.
///
/// The refresh button only exists on desktop platform families (mobile uses
/// pull-to-refresh), so this test skips itself on Android/iOS even when a
/// wide viewport is forced.
///
/// ```bash
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/board_desktop_refresh_test.dart -d macos
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final isDesktopPlatform = switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    _ => false,
  };

  // Comment bodies render via SelectableText, which find.text does not match.
  Finder commentBody(String text) =>
      find.byWidgetPredicate((w) => w is SelectableText && w.data == text);

  testWidgets('desktop board refresh button reloads the list', (tester) async {
    if (!isDesktopPlatform) {
      // Mobile platforms use pull-to-refresh; the header button is
      // desktop-only by design.
      return;
    }
    // Wide desktop viewport -> NavigationRail + header actions.
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: StreamMediaryApp()));
    // Bounded pumps: an unbounded pumpAndSettle can hang on real devices
    // where system animations keep scheduling frames.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Open the board from the rail.
    await tester.tap(find.text('留言板'));
    await tester.pump();

    // Wait for the first load to render a comment.
    var hasComment = false;
    for (var i = 0; i < 20 && !hasComment; i++) {
      await tester.pump(const Duration(seconds: 1));
      hasComment =
          find.text('probe').evaluate().isNotEmpty ||
          find.text('积极').evaluate().isNotEmpty;
    }
    expect(hasComment, isTrue, reason: 'no comment rendered from server');

    // The desktop header must expose a refresh button (tooltip 刷新).
    final refreshBtn = find.byTooltip('刷新');
    expect(
      refreshBtn,
      findsOneWidget,
      reason: 'desktop refresh button missing',
    );

    // Post a unique marker via the API. It must NOT be on screen yet (the
    // list was loaded before this post), proving the later appearance is
    // caused by the refresh, not by stale state.
    final marker = 'refresh_probe_${DateTime.now().millisecondsSinceEpoch}';
    final client = WalineClient(serverUrl: WalineClient.defaultServerUrl);
    await client.postComment(content: marker, nick: 'ci');
    await tester.pump();
    expect(
      commentBody(marker),
      findsNothing,
      reason: 'marker visible before refresh — test is not meaningful',
    );

    // Tap refresh and wait for the marker to appear in the list.
    await tester.tap(refreshBtn);
    await tester.pump();
    var markerAppeared = false;
    for (var i = 0; i < 30 && !markerAppeared; i++) {
      await tester.pump(const Duration(seconds: 1));
      markerAppeared = commentBody(marker).evaluate().isNotEmpty;
    }

    // ignore: avoid_print
    print('REFRESH markerAppeared=$markerAppeared marker=$marker');

    expect(
      markerAppeared,
      isTrue,
      reason: 'refresh did not fetch the newly posted comment',
    );
    expect(
      find.text('重试'),
      findsNothing,
      reason: 'refresh produced an error banner',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
