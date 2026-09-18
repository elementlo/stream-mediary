import 'package:flutter/material.dart';

import '../../engine/task/task_state.dart';
import '../theme/design_tokens.dart';
import '../theme/mediary_colors.dart';

/// Visual identity of a task state.
///
/// One definition per state, shared by badges, cards, history rows and the
/// downloads list — so a state can never be green in one page and blue in
/// another.
@immutable
class TaskStateStyle {
  const TaskStateStyle({
    required this.color,
    required this.container,
    required this.icon,
  });

  final Color color;
  final Color container;
  final IconData icon;

  /// Resolves the style for [state] in the current theme.
  static TaskStateStyle of(BuildContext context, TaskState state) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.mediaryColors;

    return switch (state) {
      // Idle / waiting states stay neutral — they should not compete for
      // attention with work that is actually happening.
      TaskState.created ||
      TaskState.parsing ||
      TaskState.previewReady =>
        TaskStateStyle(
          color: scheme.onSurfaceVariant,
          container: scheme.surfaceContainerHigh,
          icon: Icons.schedule_rounded,
        ),
      TaskState.queued => TaskStateStyle(
          color: scheme.onSurfaceVariant,
          container: scheme.surfaceContainerHigh,
          icon: Icons.hourglass_empty_rounded,
        ),
      // Accent (cyan) = data flowing. Distinct from primary so "downloading"
      // and "merging" are distinguishable by color alone.
      TaskState.downloading => TaskStateStyle(
          color: colors.accent,
          container: colors.accentContainer,
          icon: Icons.arrow_downward_rounded,
        ),
      TaskState.paused => TaskStateStyle(
          color: colors.warning,
          container: colors.warningContainer,
          icon: Icons.pause_rounded,
        ),
      // Primary (indigo) = work settling into a finished artifact.
      TaskState.merging => TaskStateStyle(
          color: scheme.primary,
          container: scheme.primaryContainer,
          icon: Icons.call_merge_rounded,
        ),
      TaskState.completed => TaskStateStyle(
          color: colors.success,
          container: colors.successContainer,
          icon: Icons.check_circle_rounded,
        ),
      TaskState.failed => TaskStateStyle(
          color: colors.danger,
          container: colors.dangerContainer,
          icon: Icons.error_rounded,
        ),
      TaskState.canceled => TaskStateStyle(
          color: scheme.onSurfaceVariant,
          container: scheme.surfaceContainerHigh,
          icon: Icons.cancel_rounded,
        ),
    };
  }

  /// Whether this state represents ongoing activity (drives the pulsing dot).
  static bool isLive(TaskState state) =>
      state == TaskState.downloading || state == TaskState.merging;
}

/// Compact status pill: colored dot + label.
///
/// Replaces Material's `Chip`, whose default height and padding are too heavy
/// for dense lists. The text uses the full-strength state color rather than a
/// translucent one so 11.5px labels still clear 4.5:1 contrast.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.state,
    required this.label,
  });

  final TaskState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = TaskStateStyle.of(context, state);
    return PillBadge(
      label: label,
      color: style.color,
      pulsing: TaskStateStyle.isLive(state),
      icon: style.icon,
    );
  }
}

/// Generic version of the badge for non-task states (encrypted, live, ffmpeg
/// availability) so they share the exact same shape and metrics.
class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.label,
    required this.color,
    this.pulsing = false,
    this.icon,
    this.showDot = true,
  });

  final String label;
  final Color color;
  final bool pulsing;
  final IconData? icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 12, color: color)
            else if (showDot)
              _Dot(color: color, pulsing: pulsing),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.pulsing});

  final Color color;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (!pulsing) return dot;
    return _Pulse(child: dot);
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}