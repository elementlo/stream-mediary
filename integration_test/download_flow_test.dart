import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import 'package:stream_mediary/app.dart';
import 'package:stream_mediary/engine/task/task_state.dart';
import 'package:stream_mediary/providers/app_providers.dart';

/// End-to-end download flow against the local HLS test server
/// (python3 -m http.server 8080 in /tmp/hls_test + real ffmpeg segments).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full download flow', (tester) async {
    tester.view.physicalSize = const Size(2240, 1440);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      const ProviderScope(child: StreamMediaryApp()),
    );
    await tester.pump(const Duration(seconds: 2));

    // Home shows the downloads tab.
    expect(find.text('下载中'), findsOneWidget);

    // Open the new-download page via the FAB.
    await tester.tap(find.byTooltip('新建下载'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('新建下载'), findsWidgets);

    // Enter the m3u8 URL and parse.
    await tester.enterText(
      find.byType(TextField).first,
      'http://127.0.0.1:8080/master.m3u8',
    );
    await tester.tap(find.text('解析'));

    // Wait for the preview card with the start button.
    await _pumpUntil(tester, find.text('开始下载'));
    await tester.tap(find.text('开始下载'));
    await tester.pump(const Duration(seconds: 1));

    // Back on the downloads tab; poll the store until the task completes.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StreamMediaryApp)),
    );
    final store = container.read(engineTaskStoreProvider);

    String? outputPath;
    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(seconds: 2));
      final tasks = await store.loadAllTasks();
      final done = tasks.where((t) => t.state == TaskState.completed);
      if (done.isNotEmpty) {
        outputPath = done.first.outputPath;
        break;
      }
      final failed = tasks.where((t) => t.state == TaskState.failed);
      if (failed.isNotEmpty) {
        fail('Task failed: ${failed.first.errorMsg}');
      }
    }

    expect(outputPath, isNotNull, reason: 'task did not complete in time');

    // Merged output exists and is non-empty; segments were cleaned up.
    final output = File(outputPath!);
    expect(output.existsSync(), isTrue);
    expect(output.lengthSync(), greaterThan(0));
    final segmentsDir = Directory(p.join(p.dirname(outputPath), 'segments'));
    expect(segmentsDir.existsSync(), isFalse,
        reason: 'segments dir should be removed after merge');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder,
    {Duration timeout = const Duration(seconds: 15)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!finder.evaluate().isNotEmpty &&
      DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(finder, findsOneWidget);
}
