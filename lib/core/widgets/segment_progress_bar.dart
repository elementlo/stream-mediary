import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/mediary_colors.dart';

/// The signature Mediary component: a progress bar drawn as discrete segments.
///
/// A plain [LinearProgressIndicator] can only express "percent". Mediary's real
/// unit of work is the HLS segment, so the bar renders one tick per segment —
/// the user can see how many blocks remain and whether one is stuck. This is
/// the visual expression of the product's own mechanism.
///
/// Rendering rules:
/// - One tick per segment, 2px apart.
/// - At most [maxTicks] ticks: above that, segments are bucketed so ticks never
///   get thinner than 2px (a 3000-segment stream still reads clearly).
/// - The segment currently in flight is highlighted in the accent color with a
///   breathing pulse; failed segments are flagged in red so a stuck download is
///   visible at a glance.
/// - When the task enters the merging phase the ticks collapse into a single
///   continuous bar — the "converge" motif.
class SegmentProgressBar extends StatelessWidget {
  const SegmentProgressBar({
    super.key,
    required this.totalSegments,
    required this.doneSegments,
    this.failedSegments = 0,
    this.active = true,
    this.merging = false,
    this.mergeFraction,
    this.thickness,
    this.semanticLabel,
  });

  /// Total number of segments in the playlist. Zero renders an indeterminate
  /// continuous bar (playlist not parsed yet).
  final int totalSegments;

  /// Segments that finished downloading.
  final int doneSegments;

  /// Segments currently in the failed state.
  final int failedSegments;

  /// Whether to pulse the in-flight segment. False for paused tasks.
  final bool active;

  /// Whether the task is merging. Switches to the converge presentation.
  final bool merging;

  /// Merge progress, 0..1. Only used when [merging] is true.
  final double? mergeFraction;

  /// Bar height. Defaults to 8 on touch, 6 on desktop.
  final double? thickness;

  /// Accessibility description, e.g. "进度 42%，已下载 21/50 个分片".
  final String? semanticLabel;

  /// Upper bound on rendered ticks, keeping each tick at least 2px wide.
  static const int maxTicks = 60;

  @override
  Widget build(BuildContext context) {
    final colors = context.mediaryColors;
    final profile = Theme.of(context).visualDensity;
    final compact = profile == VisualDensity.compact;
    final height = thickness ?? (compact ? 6 : 8);

    if (merging) {
      return _MergeBar(
        fraction: mergeFraction ?? 0,
        height: height,
        label: semanticLabel,
      );
    }

    if (totalSegments <= 0) {
      return _IndeterminateBar(height: height, label: semanticLabel);
    }

    final ticks = math.min(totalSegments, maxTicks);
    final perTick = totalSegments / ticks;
    final doneTicks = (doneSegments / perTick).floor().clamp(0, ticks);
    // The segment in flight is the one right after the last completed one.
    final hasActiveTick =
        active && doneSegments < totalSegments && failedSegments == 0;

    return Semantics(
      label: semanticLabel,
      value: '${(doneSegments / totalSegments * 100).round()}%',
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < ticks; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: _Tick(
                  state: _stateFor(i, doneTicks, hasActiveTick, ticks),
                  height: height,
                  colors: colors,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _TickState _stateFor(int index, int doneTicks, bool hasActive, int ticks) {
    if (index < doneTicks) {
      // A failed segment inside the completed range stays visible.
      return _TickState.done;
    }
    if (failedSegments > 0 && index >= ticks - failedSegments) {
      return _TickState.failed;
    }
    if (hasActive && index == doneTicks) return _TickState.active;
    return _TickState.pending;
  }
}

enum _TickState { done, active, failed, pending }

class _Tick extends StatelessWidget {
  const _Tick({
    required this.state,
    required this.height,
    required this.colors,
  });

  final _TickState state;
  final double height;
  final MediaryColors colors;

  @override
  Widget build(BuildContext context) {
    // Ticks are at least 2px wide; below ~6px a radius would eat the shape, so
    // only round the corners once there is room.
    final radius = BorderRadius.circular(height <= 6 ? 2 : 4);

    final color = switch (state) {
      _TickState.done => colors.doneSegment,
      _TickState.active => colors.accent,
      _TickState.failed => colors.danger,
      _TickState.pending => colors.track,
    };

    final bar = DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: const SizedBox.expand(),
    );

    if (state != _TickState.active) return bar;

    return _Pulse(child: bar);
  }
}

/// Breathing highlight for the in-flight segment.
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

/// Converge presentation used while merging: the ticks have become one body.
class _MergeBar extends StatelessWidget {
  const _MergeBar({
    required this.fraction,
    required this.height,
    this.label,
  });

  final double fraction;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.mediaryColors;
    final value = fraction.clamp(0.0, 1.0);

    return Semantics(
      label: label,
      value: '${(value * 100).round()}%',
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final filled = constraints.maxWidth * value;
            return Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.track,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                  child: const SizedBox.expand(),
                ),
                if (filled > 0)
                  SizedBox(
                    width: filled,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.doneSegment,
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Continuous indeterminate bar for an unparsed playlist.
class _IndeterminateBar extends StatelessWidget {
  const _IndeterminateBar({required this.height, this.label});

  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: const LinearProgressIndicator(value: null),
        ),
      ),
    );
  }
}