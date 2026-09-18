import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Centered empty state with a tinted icon tile, a title and an optional action.
///
/// The icon sits inside a rounded tile rather than floating bare, which gives
/// the state a focal point and keeps it from looking like a broken layout.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: Radii.lgAll,
              ),
              child: Icon(icon, size: 30, color: scheme.primary),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: Spacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: Spacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}