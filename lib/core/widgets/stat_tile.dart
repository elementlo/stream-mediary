import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Label-above-value data cell.
///
/// Used for playlist preview metrics and folder scan results. Values render with
/// tabular figures so a column of numbers aligns on the decimal.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  /// Tints the tile background — used for the single metric that matters most.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md - 1,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainer,
        borderRadius: Radii.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: scheme.onSurfaceVariant),
                const SizedBox(width: Spacing.xs + 1),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs + 1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(
              color: valueColor ?? scheme.onSurface,
              fontFeatures: tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive grid of [StatTile]s: 2 columns on narrow layouts, up to 4 wide.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children, this.maxColumns = 3});

  final List<Widget> children;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 380
            ? 2
            : maxColumns.clamp(1, children.length);
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Spacing.sm + 2,
          crossAxisSpacing: Spacing.sm + 2,
          childAspectRatio: 1.85,
          children: children,
        );
      },
    );
  }
}