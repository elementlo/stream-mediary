import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_mediary/core/platform/platform_profile.dart';
import 'package:stream_mediary/core/theme/app_theme.dart';
import 'package:stream_mediary/core/theme/design_tokens.dart';
import 'package:stream_mediary/core/theme/mediary_colors.dart';
import 'package:stream_mediary/core/widgets/empty_state.dart';
import 'package:stream_mediary/core/widgets/mediary_card.dart';
import 'package:stream_mediary/core/widgets/mediary_scaffold.dart';
import 'package:stream_mediary/core/widgets/section_header.dart';
import 'package:stream_mediary/core/widgets/segment_progress_bar.dart';
import 'package:stream_mediary/core/widgets/stat_tile.dart';
import 'package:stream_mediary/core/widgets/status_badge.dart';
import 'package:stream_mediary/engine/task/task_state.dart';

/// Wraps [child] in the app theme so widget tests exercise the real theme
/// rather than Material defaults.
Widget harness(
  Widget child, {
  Brightness brightness = Brightness.light,
  PlatformProfile? profile,
}) {
  final resolved = profile ?? PlatformProfile.material;
  return PlatformProfileHarness(
    profile: resolved,
    child: MaterialApp(
      theme: brightness == Brightness.dark
          ? AppTheme.dark(profile: resolved)
          : AppTheme.light(profile: resolved),
      home: Scaffold(body: child),
    ),
  );
}

/// Installs a [PlatformScope] around the app under test.
class PlatformProfileHarness extends StatelessWidget {
  const PlatformProfileHarness({
    super.key,
    required this.profile,
    required this.child,
  });

  final PlatformProfile profile;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      PlatformScope(profile: profile, child: child);
}

void main() {
  group('design tokens', () {
    test('spacing scale is strictly increasing', () {
      expect(Spacing.xs, lessThan(Spacing.sm));
      expect(Spacing.sm, lessThan(Spacing.md));
      expect(Spacing.md, lessThan(Spacing.lg));
      expect(Spacing.lg, lessThan(Spacing.xl));
      expect(Spacing.xl, lessThan(Spacing.xxl));
    });

    test('radii are three-tiered', () {
      expect(Radii.sm, lessThan(Radii.md));
      expect(Radii.md, lessThan(Radii.lg));
      expect(Radii.lg, lessThan(Radii.xl));
    });

    test('progress motion matches the engine event throttle', () {
      // The engine throttles progress events at 500ms; the bar animates in
      // 450ms so it climbs smoothly instead of stepping.
      expect(Motion.progress.inMilliseconds, lessThanOrEqualTo(500));
      expect(Motion.progress.inMilliseconds, greaterThan(Motion.standard.inMilliseconds));
    });

    test('desktop content widths are capped below common window widths', () {
      expect(Breakpoints.contentForm, lessThanOrEqualTo(800));
      expect(Breakpoints.contentList, lessThanOrEqualTo(1000));
      expect(Breakpoints.contentForm, lessThan(Breakpoints.contentList));
    });
  });

  group('color scheme', () {
    test('light and dark schemes are hand-authored, not seeded', () {
      // A seed-derived scheme would place primaryContainer at a desaturated
      // tint. Assert the exact authored brand values instead.
      expect(MediaryPalette.light.primary, const Color(0xFF4F46E5));
      expect(MediaryPalette.dark.primary, const Color(0xFF7C8CFF));
      expect(MediaryPalette.light.primaryContainer, const Color(0xFFE8E9FE));
    });

    test('surface layering is distinct at every step', () {
      final s = MediaryPalette.dark;
      final steps = [
        s.surface,
        s.surfaceContainerLow,
        s.surfaceContainer,
        s.surfaceContainerHigh,
      ];
      expect(steps.toSet().length, steps.length,
          reason: 'each surface step must differ so cards read as raised');
    });

    test('semantic colors are distinct per meaning', () {
      final c = MediaryColors.light;
      final meanings = [c.success, c.warning, c.accent, c.danger];
      expect(meanings.toSet().length, meanings.length);
    });

    testWidgets('theme exposes MediaryColors extension', (tester) async {
      late MediaryColors resolved;
      await tester.pumpWidget(
        harness(
          Builder(builder: (context) {
            resolved = context.mediaryColors;
            return const SizedBox();
          }),
        ),
      );
      expect(resolved.success, MediaryColors.light.success);
    });

    testWidgets('dark theme resolves dark semantic colors', (tester) async {
      late MediaryColors resolved;
      await tester.pumpWidget(
        harness(
          Builder(builder: (context) {
            resolved = context.mediaryColors;
            return const SizedBox();
          }),
          brightness: Brightness.dark,
        ),
      );
      expect(resolved.success, MediaryColors.dark.success);
    });
  });

  group('platform profile', () {
    test('touch and desktop profiles differ where it matters', () {
      const touch = PlatformProfile.material;
      const desktop = PlatformProfile.desktop;

      expect(desktop.cardPadding, greaterThan(touch.cardPadding));
      expect(desktop.listItemHeight, lessThan(touch.listItemHeight));
      expect(desktop.minTapTarget, lessThan(touch.minTapTarget));
      expect(desktop.showPointerAffordances, isTrue);
      expect(touch.showPointerAffordances, isFalse);
      expect(desktop.clampScrollPhysics, isTrue);
      expect(touch.clampScrollPhysics, isFalse);
    });

    test('iOS uses Cupertino transitions, Android does not', () {
      expect(PlatformProfile.cupertino.useCupertinoPageTransition, isTrue);
      expect(PlatformProfile.material.useCupertinoPageTransition, isFalse);
    });

    test('navigation form switches at the documented breakpoints', () {
      const p = PlatformProfile.desktop;
      expect(p.navFormFor(400), NavForm.bottomBar);
      expect(p.navFormFor(Breakpoints.navigationRail - 1), NavForm.bottomBar);
      expect(p.navFormFor(Breakpoints.navigationRail), NavForm.railCollapsed);
      expect(p.navFormFor(Breakpoints.railExtended - 1), NavForm.railCollapsed);
      expect(p.navFormFor(Breakpoints.railExtended), NavForm.railExtended);
    });
  });

  group('SegmentProgressBar', () {
    testWidgets('renders one tick per segment up to the cap', (tester) async {
      await tester.pumpWidget(
        harness(
          const SizedBox(
            width: 300,
            child: SegmentProgressBar(totalSegments: 24, doneSegments: 12),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // 24 segments -> 24 tick decorations.
      final decorations = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((d) => d.decoration is BoxDecoration)
          .toList();
      expect(decorations.length, greaterThanOrEqualTo(24));
    });

    testWidgets('buckets large playlists down to the tick cap', (tester) async {
      await tester.pumpWidget(
        harness(
          const SizedBox(
            width: 300,
            child: SegmentProgressBar(totalSegments: 3000, doneSegments: 1500),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final ticks = find.byType(DecoratedBox);
      // At most maxTicks rendered, never one per segment.
      expect(
        tester.widgetList(ticks).length,
        lessThanOrEqualTo(SegmentProgressBar.maxTicks + 2),
      );
    });

    testWidgets('merging phase collapses to a continuous bar', (tester) async {
      await tester.pumpWidget(
        harness(
          const SizedBox(
            width: 300,
            child: SegmentProgressBar(
              totalSegments: 24,
              doneSegments: 24,
              merging: true,
              mergeFraction: 0.5,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // No per-segment Row of ticks while merging.
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('unparsed playlist falls back to indeterminate', (tester) async {
      await tester.pumpWidget(
        harness(
          const SizedBox(
            width: 300,
            child: SegmentProgressBar(totalSegments: 0, doneSegments: 0),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('exposes an accessible progress label', (tester) async {
      await tester.pumpWidget(
        harness(
          const SizedBox(
            width: 300,
            child: SegmentProgressBar(
              totalSegments: 50,
              doneSegments: 21,
              semanticLabel: '进度 42%，已下载 21/50 个分片',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final semantics = tester.getSemantics(
        find.byType(SegmentProgressBar),
      );
      expect(semantics.label, contains('21/50'));
      expect(semantics.value, '42%');
    });

    testWidgets('renders at every task state without overflow', (tester) async {
      for (final total in [1, 5, 60, 61, 500, 5000]) {
        await tester.pumpWidget(
          harness(
            SizedBox(
              width: 320,
              child: SegmentProgressBar(
                totalSegments: total,
                doneSegments: total ~/ 3,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 20));
        expect(tester.takeException(), isNull, reason: 'total=$total');
      }
    });
  });

  group('StatusBadge', () {
    testWidgets('renders the label for every task state', (tester) async {
      for (final state in TaskState.values) {
        await tester.pumpWidget(
          harness(StatusBadge(state: state, label: state.name)),
        );
        await tester.pump(const Duration(milliseconds: 20));
        expect(find.text(state.name), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'state=$state');
      }
    });

    test('state styles are distinct per semantic meaning', () {
      // Downloading and merging must differ: one is "flowing", the other is
      // "settling". Collapsing them would lose the color vocabulary.
      expect(TaskStateStyle.isLive(TaskState.downloading), isTrue);
      expect(TaskStateStyle.isLive(TaskState.merging), isTrue);
      expect(TaskStateStyle.isLive(TaskState.paused), isFalse);
      expect(TaskStateStyle.isLive(TaskState.completed), isFalse);
    });

    testWidgets('downloading and merging use different colors', (tester) async {
      late Color downloading;
      late Color merging;
      await tester.pumpWidget(
        harness(
          Builder(builder: (context) {
            downloading =
                TaskStateStyle.of(context, TaskState.downloading).color;
            merging = TaskStateStyle.of(context, TaskState.merging).color;
            return const SizedBox();
          }),
        ),
      );
      expect(downloading, isNot(merging));
    });
  });

  group('MediaryCard', () {
    testWidgets('renders content and honors the accent strip', (tester) async {
      await tester.pumpWidget(
        harness(
          const MediaryCard(
            accent: Color(0xFF22D3EE),
            child: Text('task'),
          ),
        ),
      );
      expect(find.text('task'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accent strip does not cause a constraint loop', (tester) async {
      // Regression guard: an earlier Row+stretch implementation produced an
      // unbounded-height error inside a scrollable.
      await tester.pumpWidget(
        harness(
          ListView(
            children: const [
              MediaryCard(
                accent: Color(0xFF22D3EE),
                child: Text('a'),
              ),
              MediaryCard(
                accent: Color(0xFF7C8CFF),
                child: Text('b'),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('is tappable when onTap is provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        harness(
          MediaryCard(
            onTap: () => tapped = true,
            child: const Text('tap me'),
          ),
        ),
      );
      await tester.tap(find.text('tap me'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('MediaryScaffold', () {
    testWidgets('mobile shows an AppBar with the title', (tester) async {
      await tester.pumpWidget(
        harness(
          const MediaryScaffold(title: '下载中', child: Text('body')),
        ),
      );
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('下载中'), findsOneWidget);
    });

    testWidgets('desktop hides the AppBar and centers a capped column',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        harness(
          const MediaryScaffold(title: '设置', child: Text('body')),
          profile: PlatformProfile.desktop,
        ),
      );
      await tester.pump();

      expect(find.byType(AppBar), findsNothing,
          reason: 'desktop uses an in-content title, not a toolbar');
      expect(find.text('设置'), findsOneWidget);

      // The content column must be capped, not stretched to 1600px.
      final width = tester.getSize(find.text('body')).width;
      expect(width, lessThanOrEqualTo(Breakpoints.contentList.toDouble()));
    });

    testWidgets('desktop renders a subtitle when provided', (tester) async {
      await tester.pumpWidget(
        harness(
          const MediaryScaffold(
            title: '下载中',
            subtitle: '2 个进行中',
            child: Text('body'),
          ),
          profile: PlatformProfile.desktop,
        ),
      );
      await tester.pump();
      expect(find.text('2 个进行中'), findsOneWidget);
    });
  });

  group('SectionHeader', () {
    testWidgets('renders the label', (tester) async {
      await tester.pumpWidget(harness(const SectionHeader('并发数')));
      expect(find.text('并发数'), findsOneWidget);
    });

    testWidgets('renders a trailing widget when supplied', (tester) async {
      await tester.pumpWidget(
        harness(
          const SectionHeader('并发数', trailing: Icon(Icons.info_outline)),
        ),
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('renders icon, title, message and action', (tester) async {
      await tester.pumpWidget(
        harness(
          EmptyState(
            icon: Icons.download_done_rounded,
            title: '暂无下载任务',
            message: '点击下方按钮添加地址',
            action: FilledButton(onPressed: () {}, child: const Text('新建')),
          ),
        ),
      );
      expect(find.text('暂无下载任务'), findsOneWidget);
      expect(find.text('点击下方按钮添加地址'), findsOneWidget);
      expect(find.text('新建'), findsOneWidget);
    });

    testWidgets('omits message and action when not provided', (tester) async {
      await tester.pumpWidget(
        harness(
          const EmptyState(icon: Icons.history_rounded, title: '暂无记录'),
        ),
      );
      expect(find.text('暂无记录'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('StatTile', () {
    testWidgets('renders label above value', (tester) async {
      await tester.pumpWidget(
        harness(const StatTile(label: '分片数量', value: '248')),
      );
      expect(find.text('分片数量'), findsOneWidget);
      expect(find.text('248'), findsOneWidget);
    });

    testWidgets('grid lays out tiles without overflow at narrow widths',
        (tester) async {
      await tester.pumpWidget(
        harness(
          const SizedBox(
            width: 320,
            child: StatGrid(
              children: [
                StatTile(label: '分片数量', value: '248'),
                StatTile(label: '总时长', value: '41:22'),
                StatTile(label: '估算大小', value: '386 MB'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('theme component defaults', () {
    testWidgets('cards are flat with a hairline border', (tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        harness(
          Builder(builder: (context) {
            theme = Theme.of(context);
            return const SizedBox();
          }),
        ),
      );
      expect(theme.cardTheme.elevation, 0);
      expect(theme.useMaterial3, isTrue);
    });

    testWidgets('buttons use the medium radius tier', (tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        harness(
          Builder(builder: (context) {
            theme = Theme.of(context);
            return const SizedBox();
          }),
        ),
      );
      final shape = theme.filledButtonTheme.style?.shape?.resolve({})
          as RoundedRectangleBorder?;
      expect(shape?.borderRadius, Radii.mdAll);
    });

    testWidgets('titleMedium carries tabular figures', (tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        harness(
          Builder(builder: (context) {
            theme = Theme.of(context);
            return const SizedBox();
          }),
        ),
      );
      expect(theme.textTheme.titleMedium?.fontFeatures, contains(tabularFigures.first));
      expect(theme.textTheme.bodySmall?.fontFeatures, contains(tabularFigures.first));
    });

    testWidgets('switch thumb contrasts with its track in both states',
        (tester) async {
      // Regression: Material's default unselected switch (outline thumb on
      // surfaceContainerHighest track) is nearly invisible in this palette.
      for (final brightness in [Brightness.light, Brightness.dark]) {
        late ThemeData theme;
        await tester.pumpWidget(
          harness(
            Builder(builder: (context) {
              theme = Theme.of(context);
              return const SizedBox();
            }),
            brightness: brightness,
          ),
        );
        final style = theme.switchTheme;
        final scheme = theme.colorScheme;

        final offThumb =
            style.thumbColor!.resolve({})!;
        final offTrack =
            style.trackColor!.resolve({})!;
        final onThumb =
            style.thumbColor!.resolve({WidgetState.selected})!;
        final onTrack =
            style.trackColor!.resolve({WidgetState.selected})!;

        // Relative luminance distance: 0 = identical, 1 = black vs white.
        double contrast(Color a, Color b) =>
            (a.computeLuminance() - b.computeLuminance()).abs();

        expect(contrast(offThumb, offTrack), greaterThan(0.3),
            reason: 'off-state thumb blends into track ($brightness)');
        expect(contrast(onThumb, onTrack), greaterThan(0.3),
            reason: 'on-state thumb blends into track ($brightness)');
        // Off state must also read as "off": track stays a neutral surface,
        // not the primary color.
        expect(offTrack, isNot(scheme.primary));
      }
    });
  });
}