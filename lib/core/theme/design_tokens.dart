import 'package:flutter/widgets.dart';

/// Design tokens for Mediary.
///
/// Every spacing, radius, duration and type size in the app resolves to one of
/// these constants — no magic numbers in feature code. See
/// `docs/ui-redesign.md` for the rationale behind each value.
abstract final class Spacing {
  /// 4 — gap between an icon and its label.
  static const double xs = 4;

  /// 8 — gap between inline elements.
  static const double sm = 8;

  /// 12 — gap between elements inside a card.
  static const double md = 12;

  /// 16 — card padding on touch platforms.
  static const double lg = 16;

  /// 20 — card padding on desktop, section spacing.
  static const double xl = 20;

  /// 32 — page-level breathing room.
  static const double xxl = 32;
}

/// Corner radii. Deliberately three-tiered (buttons 12 / cards 16 / sheets 22)
/// so surfaces do not all read as the same rounded rectangle.
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Motion durations and curves.
abstract final class Motion {
  /// 120ms — hover and press feedback.
  static const Duration fast = Duration(milliseconds: 120);

  /// 200ms — standard state changes.
  static const Duration standard = Duration(milliseconds: 200);

  /// 320ms — expand/collapse and page transitions.
  static const Duration emphasized = Duration(milliseconds: 320);

  /// 450ms — progress advancement. Matched to the engine's 500ms event
  /// throttle so bars climb smoothly instead of stepping.
  static const Duration progress = Duration(milliseconds: 450);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutQuint;
  static const Curve exit = Curves.easeIn;
}

/// Tabular figures, applied to every number that changes in place (speed,
/// size, percentage, segment counts). Without this the digits reflow on each
/// progress tick and the whole row jitters.
const List<FontFeature> tabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];

/// Layout breakpoints for adaptive navigation and content width.
abstract final class Breakpoints {
  /// Below this width: bottom navigation bar.
  static const double navigationRail = 640;

  /// At or above this width: rail expands to show labels.
  static const double railExtended = 1024;

  /// Max content width for form-like pages (new download, settings, merge).
  static const double contentForm = 760;

  /// Max content width for list pages (downloads, history).
  static const double contentList = 960;
}

/// Minimum interactive target sizes.
abstract final class TapTarget {
  static const double touch = 48;
  static const double pointer = 32;
}