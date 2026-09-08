import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:stream_mediary/app.dart';
import 'package:stream_mediary/core/router/app_router.dart';

/// Verifies the navigation stack so that system back / swipe-back from the
/// new-download page returns to the downloads tab instead of exiting the app.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new-download page is pushed and back returns to downloads',
      (tester) async {
    tester.view.physicalSize = const Size(2240, 1440);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      const ProviderScope(child: StreamMediaryApp()),
    );
    await tester.pump(const Duration(seconds: 2));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(StreamMediaryApp)),
    );
    final router = container.read(routerProvider);

    // Home shows the downloads tab; stack has exactly one page.
    expect(find.text('下载中'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.matches.length, 1);

    // Open the new-download page via the FAB.
    await tester.tap(find.byTooltip('新建下载'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The new page must be PUSHED on top, not replace the stack.
    expect(find.text('解析'), findsOneWidget);
    final stackDepth = router.routerDelegate.currentConfiguration.matches.length;
    expect(stackDepth, greaterThanOrEqualTo(2),
        reason: 'new-download page should be pushed, stack depth was $stackDepth');

    // canPop must be true so a back gesture pops instead of exiting.
    expect(router.routerDelegate.canPop(), isTrue,
        reason: 'router should be able to pop back to downloads');

    // Simulate the system back gesture / button.
    await router.routerDelegate.popRoute();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // We are back on the downloads tab, and the app is still alive.
    expect(find.text('下载中'), findsOneWidget);
    expect(router.routerDelegate.canPop(), isFalse,
        reason: 'downloads tab is the root; nothing left to pop');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
