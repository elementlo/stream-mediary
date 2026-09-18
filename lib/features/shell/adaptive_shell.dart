import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/platform/platform_profile.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/mediary_colors.dart';
import '../../core/widgets/status_badge.dart';
import '../../engine/task/task_state.dart';
import '../../providers/app_providers.dart';

/// Adaptive navigation shell.
///
/// - `< 640px`  → bottom [NavigationBar] with a FAB (phone convention).
/// - `640–1023` → icon-only [NavigationRail].
/// - `>= 1024`  → expanded rail carrying app identity and a live summary of
///   in-progress work, which is the desktop convention and puts useful state
///   where the eye already is.
class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  static const List<_Destination> _destinations = [
    _Destination(
      path: '/downloads',
      icon: Icons.download_rounded,
      selectedIcon: Icons.download_rounded,
    ),
    _Destination(
      path: '/history',
      icon: Icons.history_rounded,
      selectedIcon: Icons.history_rounded,
    ),
    _Destination(
      path: '/merge',
      icon: Icons.call_merge_rounded,
      selectedIcon: Icons.call_merge_rounded,
    ),
    _Destination(
      path: '/settings',
      icon: Icons.settings_rounded,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  int _indexFor(String path) {
    final i = _destinations.indexWhere((d) => path.startsWith(d.path));
    return i < 0 ? 0 : i;
  }

  void _onSelect(BuildContext context, int index) =>
      context.go(_destinations[index].path);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = context.platformProfile;
    final selected = _indexFor(location);

    final labels = [
      l10n.navDownloads,
      l10n.navHistory,
      l10n.navMerge,
      l10n.navSettings,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final form = profile.navFormFor(constraints.maxWidth);

        if (form == NavForm.bottomBar) {
          return _BottomBarLayout(
            selectedIndex: selected,
            onSelect: (i) => _onSelect(context, i),
            destinations: [
              for (var i = 0; i < _destinations.length; i++)
                NavigationDestination(
                  icon: Icon(_destinations[i].icon),
                  label: labels[i],
                ),
            ],
            newDownloadLabel: l10n.newDownload,
            child: child,
          );
        }

        return _RailLayout(
          selectedIndex: selected,
          onSelect: (i) => _onSelect(context, i),
          destinations: [
            for (var i = 0; i < _destinations.length; i++)
              NavigationRailDestination(
                icon: Icon(_destinations[i].icon),
                label: Text(labels[i]),
              ),
          ],
          extended: form == NavForm.railExtended,
          newDownloadLabel: l10n.newDownload,
          child: child,
        );
      },
    );
  }
}

class _Destination {
  const _Destination({
    required this.path,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final IconData icon;
  final IconData selectedIcon;
}

class _BottomBarLayout extends StatelessWidget {
  const _BottomBarLayout({
    required this.selectedIndex,
    required this.onSelect,
    required this.destinations,
    required this.newDownloadLabel,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<NavigationDestination> destinations;
  final String newDownloadLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/new'),
        tooltip: newDownloadLabel,
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.mediaryHairline, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelect,
          destinations: destinations,
        ),
      ),
    );
  }
}

class _RailLayout extends StatelessWidget {
  const _RailLayout({
    required this.selectedIndex,
    required this.onSelect,
    required this.destinations,
    required this.extended,
    required this.newDownloadLabel,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<NavigationRailDestination> destinations;
  final bool extended;
  final String newDownloadLabel;
  final Widget child;

  /// Width of the extended rail. `NavigationRail.leading` / `trailing` hand
  /// their children UNBOUNDED width constraints, so any content that stretches
  /// (or uses Expanded) must be wrapped in a fixed-width box of this size
  /// minus the horizontal padding applied around it.
  static const double _extendedRailWidth = 216;
  static const double _railContentWidth = _extendedRailWidth - Spacing.md * 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.mediaryColors;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border(
                right: BorderSide(color: colors.hairline, width: 1),
              ),
            ),
            child: NavigationRail(
              selectedIndex: selectedIndex,
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              groupAlignment: -0.85,
              onDestinationSelected: onSelect,
              minWidth: 76,
              minExtendedWidth: _extendedRailWidth,
              leading: Padding(
                padding: EdgeInsets.fromLTRB(
                  extended ? Spacing.md : Spacing.sm,
                  Spacing.lg,
                  extended ? Spacing.md : Spacing.sm,
                  Spacing.sm,
                ),
                child: extended
                    ? SizedBox(
                        width: _railContentWidth,
                        child: _BrandHeader(
                            onNewDownload: () => context.push('/new')),
                      )
                    : _NewDownloadIconButton(
                        onPressed: () => context.push('/new'),
                        label: newDownloadLabel,
                      ),
              ),
              destinations: destinations,
              trailing: extended
                  ? Padding(
                      padding: const EdgeInsets.only(top: Spacing.xl),
                      child: SizedBox(
                        width: _railContentWidth,
                        child: const _ActiveTaskSummary(),
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// App identity plus the primary action, pinned to the top of the wide rail.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onNewDownload});

  final VoidCallback onNewDownload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: Spacing.xs,
            bottom: Spacing.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: 17,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(width: Spacing.sm + 1),
              Text('Mediary', style: text.titleMedium),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onNewDownload,
          icon: const Icon(Icons.add_rounded, size: 17),
          label: const Text('新建'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            minimumSize: const Size(0, 38),
          ),
        ),
      ],
    );
  }
}

class _NewDownloadIconButton extends StatelessWidget {
  const _NewDownloadIconButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: IconButton.filled(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded),
        style: IconButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.square(40),
          shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
        ),
      ),
    );
  }
}

/// Live list of in-progress tasks, shown in the wide rail.
///
/// Gives desktop users a persistent glance at what is running without
/// navigating back to the downloads tab.
class _ActiveTaskSummary extends ConsumerWidget {
  const _ActiveTaskSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tasks = ref.watch(taskListProvider);
    final active = tasks.values
        .where((t) => !t.state.isTerminal && t.state != TaskState.previewReady)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (active.isEmpty) return const SizedBox.shrink();

    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: Spacing.xs, bottom: Spacing.sm),
            child: Text(
              l10n.navActive,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          for (final task in active.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm - 1),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: TaskStateStyle.of(context, task.state).color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm - 1),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}