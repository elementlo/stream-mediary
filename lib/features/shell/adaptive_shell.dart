import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';

/// Adaptive navigation shell.
///
/// Uses a [NavigationRail] on wide layouts (>= 720 logical px, extended at
/// >= 1000) and a bottom [NavigationBar] on narrow layouts, per Material 3.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  static const double _railBreakpoint = 720;
  static const double _extendedBreakpoint = 1000;

  int _indexFor(String path) {
    if (path.startsWith('/history')) return 1;
    if (path.startsWith('/merge')) return 2;
    if (path.startsWith('/settings')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/downloads');
      case 1:
        context.go('/history');
      case 2:
        context.go('/merge');
      case 3:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedIndex = _indexFor(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= _railBreakpoint;
        final extended = constraints.maxWidth >= _extendedBreakpoint;

        final destinations = [
          (icon: Icons.download_rounded, label: l10n.navDownloads),
          (icon: Icons.history_rounded, label: l10n.navHistory),
          (icon: Icons.call_merge_rounded, label: l10n.navMerge),
          (icon: Icons.settings_rounded, label: l10n.navSettings),
        ];

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  extended: extended,
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  onDestinationSelected: (i) => _onTap(context, i),
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: FloatingActionButton(
                      onPressed: () => context.push('/new'),
                      tooltip: l10n.newDownload,
                      child: const Icon(Icons.add),
                    ),
                  ),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          body: child,
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/new'),
            tooltip: l10n.newDownload,
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => _onTap(context, i),
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
