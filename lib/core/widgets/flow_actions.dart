import 'package:flutter/material.dart';

import '../platform/platform_profile.dart';
import '../theme/design_tokens.dart';

/// Action row for form/flow pages (new download, batch import, merge).
///
/// Per the design spec (`docs/ui-redesign.md` §7.4): primary buttons are
/// full-width on mobile flow pages, but **right-aligned** on desktop.
class FlowActions extends StatelessWidget {
  const FlowActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.platformProfile.isDesktop;

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: Spacing.sm),
            children[i],
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: Spacing.sm),
          children[i],
        ],
      ],
    );
  }
}
