import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:stream_mediary/app.dart';

/// Verifies the new Merge tab renders and is reachable from navigation.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('merge tab is reachable and shows the folder picker UI',
      (tester) async {
    tester.view.physicalSize = const Size(2240, 1440);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      const ProviderScope(child: StreamMediaryApp()),
    );
    await tester.pump(const Duration(seconds: 2));

    // The 4th navigation destination exists.
    expect(find.text('合并'), findsOneWidget);

    // Switch to the merge tab.
    await tester.tap(find.text('合并'));
    await tester.pump(const Duration(seconds: 1));

    // Merge page content is visible.
    expect(find.text('切片文件夹'), findsOneWidget);
    expect(find.text('选择文件夹'), findsWidgets);
    expect(find.text('开始合并'), findsOneWidget);

    // Start button is disabled without a folder.
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('开始合并'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
