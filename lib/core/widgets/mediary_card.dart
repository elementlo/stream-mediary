import 'package:flutter/material.dart';

import '../platform/platform_profile.dart';
import '../theme/design_tokens.dart';
import '../theme/mediary_colors.dart';

/// Flat surface card with a hairline border.
///
/// No elevation by default — layering comes from the surface color step and a
/// 1px border. On desktop it raises its background on hover, since pointer
/// affordance is expected there.
///
/// [accent] paints a 3px status-colored strip on the leading edge. Used only
/// for in-progress tasks so the active rows can be found by scanning.
class MediaryCard extends StatefulWidget {
  const MediaryCard({
    super.key,
    required this.child,
    this.accent,
    this.onTap,
    this.padding,
    this.hoverable = true,
  });

  final Widget child;

  /// Leading status strip color. Null renders a plain card.
  final Color? accent;

  final VoidCallback? onTap;

  /// Overrides the platform-derived padding.
  final EdgeInsetsGeometry? padding;

  /// Whether to raise the surface on pointer hover.
  final bool hoverable;

  @override
  State<MediaryCard> createState() => _MediaryCardState();
}

class _MediaryCardState extends State<MediaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.mediaryColors;
    final profile = context.platformProfile;

    final canHover = widget.hoverable &&
        profile.showPointerAffordances &&
        widget.onTap != null;

    final background = canHover && _hovered
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLow;

    final content = Padding(
      padding: widget.padding ??
          EdgeInsets.all(profile.isDesktop ? Spacing.xl : Spacing.lg),
      child: widget.child,
    );

    // Stack rather than a Row with `stretch`: the card's height comes from its
    // content, so stretching a sibling to match it would be circular.
    final body = widget.accent == null
        ? content
        : Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: ColoredBox(color: widget.accent!),
              ),
              content,
            ],
          );

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: canHover ? (_) => setState(() => _hovered = true) : null,
      onExit: canHover ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.enter,
        decoration: BoxDecoration(
          color: background,
          borderRadius: Radii.lgAll,
          border: Border.all(color: colors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.onTap == null
            ? body
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  splashColor: scheme.primary.withValues(alpha: 0.06),
                  highlightColor: scheme.primary.withValues(alpha: 0.04),
                  child: body,
                ),
              ),
      ),
    );
  }
}