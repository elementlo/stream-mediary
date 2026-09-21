import 'package:flutter/material.dart';
import 'package:flutter_driver/flutter_driver.dart'
    show Timeline, TimelineSummary;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:stream_mediary/app.dart';

/// Measures scroll performance of the settings page on a real device.
///
/// Run in PROFILE mode for meaningful numbers:
///
/// ```bash
/// flutter drive --profile \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/settings_scroll_perf_test.dart \
///   -d <device-id>
/// ```
///
/// Prints a compact frame-timing summary (build / raster milliseconds) so
/// jank sources can be identified without opening DevTools.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings page scroll frame timings', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: StreamMediaryApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Navigate to the settings tab (bottom navigation on this narrow view).
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(ListView), findsOneWidget);

    // Warm-up scroll so first-frame costs (layout, image/font caches) are
    // excluded from the measured window.
    await tester.fling(find.byType(ListView), const Offset(0, -400), 1200);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1200);
    await tester.pumpAndSettle();

    final timeline = await binding.traceTimeline(() async {
      for (var i = 0; i < 4; i++) {
        await tester.fling(find.byType(ListView), const Offset(0, -500), 1500);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 4; i++) {
        await tester.fling(find.byType(ListView), const Offset(0, 500), 1500);
        await tester.pumpAndSettle();
      }
    });

    final summary = TimelineSummary.summarize(
      Timeline.fromJson(timeline.toJson()),
    );
    final json = summary.summaryJson;
    const keys = [
      'average_frame_build_time_millis',
      '90th_percentile_frame_build_time_millis',
      '99th_percentile_frame_build_time_millis',
      'average_frame_rasterizer_time_millis',
      '90th_percentile_frame_rasterizer_time_millis',
      '99th_percentile_frame_rasterizer_time_millis',
      'missed_build_count',
      'missed_raster_count',
      'frame_count',
    ];
    // ignore: avoid_print
    print('SCROLL_PERF {${keys.map((k) => '"$k": ${json[k]}').join(', ')}}');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
