import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Small uppercase-ish section label above a group of controls.
///
/// Replaces the `_SectionTitle` widget that was duplicated in the settings and
/// merge pages. Muted rather than primary-colored: on a settings page there are
/// six of these, and coloring them all in the brand color makes the page shout.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.trailing});

  final String label;

  /// Optional control aligned to the right of the label.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: Spacing.xl,
        bottom: Spacing.md,
        left: Spacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (trailing case final Widget t) t,
        ],
      ),
    );
  }
}