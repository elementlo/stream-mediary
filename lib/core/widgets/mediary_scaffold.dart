import 'package:flutter/material.dart';

import '../platform/platform_profile.dart';
import '../theme/design_tokens.dart';

/// Page scaffold that adapts its chrome to the platform.
///
/// Mobile: standard [AppBar] with the page title.
/// Desktop: no AppBar; the page renders a large title inside the content
/// column instead, which is the native desktop convention and avoids a
/// title-in-a-bar repeated on every window.
///
/// [maxWidth] caps the content column and centers it, so a 1400px window does
/// not stretch a form into an unreadable banner.
class MediaryScaffold extends StatelessWidget {
  const MediaryScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.maxWidth = Breakpoints.contentList,
    this.padding,
    this.floatingActionButton,
    this.leading,
  });

  final String title;

  /// Optional secondary line under the desktop title.
  final String? subtitle;

  /// Toolbar actions. On desktop these sit on the title row.
  final List<Widget> actions;

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Widget? floatingActionButton;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final profile = context.platformProfile;
    final isDesktop = profile.isDesktop;
    final horizontal = isDesktop ? Spacing.xxl : Spacing.lg;
    final effectivePadding = padding ??
        EdgeInsets.fromLTRB(
          horizontal,
          isDesktop ? Spacing.xl : Spacing.lg,
          horizontal,
          Spacing.xxl,
        );

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: effectivePadding, child: child),
      ),
    );

    if (!isDesktop) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: leading,
          actions: actions.isEmpty
              ? null
              : [for (final a in actions) Padding(
                  padding: const EdgeInsets.only(right: Spacing.xs),
                  child: a,
                )],
        ),
        body: content,
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              Spacing.xl,
              horizontal,
              Spacing.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _DesktopTitleRow(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                  leading: leading,
                ),
              ),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _DesktopTitleRow extends StatelessWidget {
  const _DesktopTitleRow({
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: Spacing.sm),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: text.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        if (actions.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in actions) ...[
                a,
                const SizedBox(width: Spacing.xs + 2),
              ],
            ],
          ),
      ],
    );
  }
}