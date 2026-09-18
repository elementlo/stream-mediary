import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// The family of conventions a platform follows.
///
/// Adaptation is driven by this enum rather than scattered `Platform.isX`
/// checks, so "how does a desktop behave" is answered in exactly one place.
enum PlatformFamily {
  /// Android — Material conventions.
  material,

  /// iOS — Cupertino conventions.
  cupertino,

  /// macOS / Windows / Linux — pointer-driven desktop conventions.
  desktop,
}

/// Per-platform adaptation profile.
///
/// Defines the differences that make the app feel native on each platform while
/// keeping one design language. See `docs/ui-redesign.md` §8.
@immutable
class PlatformProfile {
  const PlatformProfile._({
    required this.family,
    required this.density,
    required this.cardPadding,
    required this.listItemHeight,
    required this.minTapTarget,
    required this.showPointerAffordances,
    required this.useCupertinoPageTransition,
    required this.showScrollbarsAlways,
    required this.clampScrollPhysics,
  });

  final PlatformFamily family;

  /// `compact` on desktop (pointer allows tighter targets), `comfortable`
  /// on touch platforms.
  final VisualDensity density;

  /// Inner padding for cards.
  final double cardPadding;

  /// Minimum row height for list tiles.
  final double listItemHeight;

  /// Minimum interactive size.
  final double minTapTarget;

  /// Whether to show hover states, context menus and keyboard shortcuts.
  final bool showPointerAffordances;

  /// iOS gets horizontal slide-in transitions with edge-swipe back.
  final bool useCupertinoPageTransition;

  /// Desktop keeps scrollbars visible rather than fading them out.
  final bool showScrollbarsAlways;

  /// Desktop uses clamping physics; mobile uses platform-native bouncing/glow.
  final bool clampScrollPhysics;

  /// Resolves the profile for the current platform.
  ///
  /// In tests and on web the host OS is used, falling back to the material
  /// profile when the platform cannot be determined.
  factory PlatformProfile.resolve() {
    if (kIsWeb) {
      return PlatformProfile.desktop.copyWith(family: PlatformFamily.desktop);
    }
    if (Platform.isIOS) return PlatformProfile.cupertino;
    if (Platform.isAndroid) return PlatformProfile.material;
    return PlatformProfile.desktop;
  }

  static const PlatformProfile material = PlatformProfile._(
    family: PlatformFamily.material,
    density: VisualDensity.standard,
    cardPadding: Spacing.lg,
    listItemHeight: 56,
    minTapTarget: TapTarget.touch,
    showPointerAffordances: false,
    useCupertinoPageTransition: false,
    showScrollbarsAlways: false,
    clampScrollPhysics: false,
  );

  static const PlatformProfile cupertino = PlatformProfile._(
    family: PlatformFamily.cupertino,
    density: VisualDensity.standard,
    cardPadding: Spacing.lg,
    listItemHeight: 56,
    minTapTarget: TapTarget.touch,
    showPointerAffordances: false,
    useCupertinoPageTransition: true,
    showScrollbarsAlways: false,
    clampScrollPhysics: false,
  );

  static const PlatformProfile desktop = PlatformProfile._(
    family: PlatformFamily.desktop,
    density: VisualDensity.compact,
    cardPadding: Spacing.xl,
    listItemHeight: 48,
    minTapTarget: TapTarget.pointer,
    showPointerAffordances: true,
    useCupertinoPageTransition: false,
    showScrollbarsAlways: true,
    clampScrollPhysics: true,
  );

  PlatformProfile copyWith({PlatformFamily? family}) => PlatformProfile._(
        family: family ?? this.family,
        density: density,
        cardPadding: cardPadding,
        listItemHeight: listItemHeight,
        minTapTarget: minTapTarget,
        showPointerAffordances: showPointerAffordances,
        useCupertinoPageTransition: useCupertinoPageTransition,
        showScrollbarsAlways: showScrollbarsAlways,
        clampScrollPhysics: clampScrollPhysics,
      );

  /// Whether the profile is touch-first.
  bool get isTouch => family != PlatformFamily.desktop;

  /// Whether the profile is pointer-first.
  bool get isDesktop => family == PlatformFamily.desktop;

  /// Navigation form for a given window width.
  NavForm navFormFor(double width) {
    if (width < Breakpoints.navigationRail) return NavForm.bottomBar;
    if (width < Breakpoints.railExtended) return NavForm.railCollapsed;
    return NavForm.railExtended;
  }
}

/// Navigation presentation form.
enum NavForm {
  /// Bottom navigation bar (phone portrait).
  bottomBar,

  /// Icon + label rail (tablet / small desktop window).
  railCollapsed,

  /// Full rail with app identity (wide desktop window).
  railExtended,
}

/// Exposes the [PlatformProfile] through the widget tree.
///
/// Installed once at the app root so any widget can read it without touching
/// `Platform` directly.
class PlatformScope extends InheritedWidget {
  const PlatformScope({
    super.key,
    required this.profile,
    required super.child,
  });

  final PlatformProfile profile;

  static PlatformProfile of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PlatformScope>();
    return scope?.profile ?? PlatformProfile.material;
  }

  @override
  bool updateShouldNotify(PlatformScope oldWidget) =>
      oldWidget.profile != profile;
}

/// Convenience accessor: `context.platformProfile.isDesktop`.
extension PlatformProfileX on BuildContext {
  PlatformProfile get platformProfile => PlatformScope.of(this);
}