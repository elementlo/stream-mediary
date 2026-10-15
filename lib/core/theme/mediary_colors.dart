import 'package:flutter/material.dart';

/// Semantic colors that Material's [ColorScheme] has no slot for.
///
/// M3 only models `error`; Mediary needs a stable success / warning / accent
/// vocabulary because task state is the core of the UI. Exposing them through a
/// [ThemeExtension] guarantees one color per meaning across all platforms and
/// both brightnesses, instead of each page hard-coding `Colors.green`.
@immutable
class MediaryColors extends ThemeExtension<MediaryColors> {
  const MediaryColors({
    required this.success,
    required this.onSuccessContainer,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.accent,
    required this.accentContainer,
    required this.danger,
    required this.dangerContainer,
    required this.hairline,
    required this.track,
    required this.doneSegment,
  });

  /// Finished / available (download complete, ffmpeg detected).
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;

  /// Needs attention (paused, output downgraded to TS).
  final Color warning;
  final Color warningContainer;

  /// Data in motion — downloading progress, live indicator. Distinct from
  /// [ColorScheme.primary] on purpose: primary means "settled / finished",
  /// accent means "flowing right now".
  final Color accent;
  final Color accentContainer;

  /// Destructive / failed. Mirrors `ColorScheme.error` for convenience.
  final Color danger;
  final Color dangerContainer;

  /// 1px separator used for card borders and dividers.
  final Color hairline;

  /// Unfilled portion of a progress track.
  final Color track;

  /// A segment that has been downloaded and written to disk. Matches
  /// `ColorScheme.primary`: settled work is brand-colored.
  final Color doneSegment;

  // Soft Iris: every semantic hue is pulled toward the low-saturation purple
  // family so success/warning/accent/danger sit beside the primary instead of
  // fighting it. Saturation is kept ~20-30% to match the muted brand tone.
  static const MediaryColors light = MediaryColors(
    success: Color(0xFF5E8C74),
    successContainer: Color(0xFFE1EEE6),
    onSuccessContainer: Color(0xFF1E3A2C),
    warning: Color(0xFFB0813A),
    warningContainer: Color(0xFFF6EBD8),
    accent: Color(0xFF607F8C),
    accentContainer: Color(0xFFE1EBEE),
    danger: Color(0xFFB5566E),
    dangerContainer: Color(0xFFF7E3E8),
    hairline: Color(0xFFDCD8E4),
    track: Color(0xFFEAE7F0),
    doneSegment: Color(0xFF6F5B97),
  );

  static const MediaryColors dark = MediaryColors(
    success: Color(0xFF82B79B),
    successContainer: Color(0xFF1E3A2C),
    onSuccessContainer: Color(0xFFCFE8D9),
    warning: Color(0xFFD2A45E),
    warningContainer: Color(0xFF3D2F14),
    accent: Color(0xFF8FB3C0),
    accentContainer: Color(0xFF1E3238),
    danger: Color(0xFFD98A9C),
    dangerContainer: Color(0xFF43202A),
    hairline: Color(0xFF38324A),
    track: Color(0xFF2C2739),
    doneSegment: Color(0xFFB4A3D8),
  );

  @override
  MediaryColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? accent,
    Color? accentContainer,
    Color? danger,
    Color? dangerContainer,
    Color? hairline,
    Color? track,
    Color? doneSegment,
  }) {
    return MediaryColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      accent: accent ?? this.accent,
      accentContainer: accentContainer ?? this.accentContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      hairline: hairline ?? this.hairline,
      track: track ?? this.track,
      doneSegment: doneSegment ?? this.doneSegment,
    );
  }

  @override
  MediaryColors lerp(ThemeExtension<MediaryColors>? other, double t) {
    if (other is! MediaryColors) return this;
    return MediaryColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      track: Color.lerp(track, other.track, t)!,
      doneSegment: Color.lerp(doneSegment, other.doneSegment, t)!,
    );
  }
}

/// Convenience accessor: `context.mediaryColors.success`.
extension MediaryColorsX on BuildContext {
  MediaryColors get mediaryColors =>
      Theme.of(this).extension<MediaryColors>() ?? MediaryColors.dark;

  /// Shortcut for the hairline separator color.
  Color get mediaryHairline => mediaryColors.hairline;
}

/// Hand-authored color schemes.
///
/// Intentionally NOT `ColorScheme.fromSeed`: the seed algorithm flattens
/// saturation and produces the same generic palette for every app. These values
/// are tuned by hand around "Soft Iris" — a low-saturation purple (hue ~265°,
/// chroma kept to ~22-28%) so the whole UI reads calm and muted rather than
/// electric. The launcher icon is a more vivid violet of the same hue family;
/// the UI deliberately tones it down for long-session comfort.
abstract final class MediaryPalette {
  /// Brand purple — primary accent across the UI.
  static const Color brand = Color(0xFF6F5B97);

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: brand,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEBE6F4),
    onPrimaryContainer: Color(0xFF2A2140),
    secondary: Color(0xFF8C82A6),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEDEAF4),
    onSecondaryContainer: Color(0xFF2E2A3C),
    tertiary: Color(0xFF607F8C),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE1EBEE),
    onTertiaryContainer: Color(0xFF1E3238),
    error: Color(0xFFB5566E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF7E3E8),
    onErrorContainer: Color(0xFF43131F),
    surface: Color(0xFFFAF9FC),
    onSurface: Color(0xFF1D1A24),
    onSurfaceVariant: Color(0xFF6A6478),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF3F1F7),
    surfaceContainerHigh: Color(0xFFEBE8F1),
    surfaceContainerHighest: Color(0xFFE4E0EC),
    outline: Color(0xFFDCD8E4),
    outlineVariant: Color(0xFFEAE7F0),
    shadow: Color(0xFF1A1424),
    scrim: Color(0xFF1A1424),
    inverseSurface: Color(0xFF2C2739),
    onInverseSurface: Color(0xFFF4F2F8),
    inversePrimary: Color(0xFFC3B6E0),
    surfaceTint: brand,
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB4A3D8),
    onPrimary: Color(0xFF241C36),
    primaryContainer: Color(0xFF3B3155),
    onPrimaryContainer: Color(0xFFE4DCF2),
    secondary: Color(0xFFA79DBF),
    onSecondary: Color(0xFF1F1A2B),
    secondaryContainer: Color(0xFF332C45),
    onSecondaryContainer: Color(0xFFDAD3E8),
    tertiary: Color(0xFF8FB3C0),
    onTertiary: Color(0xFF16242A),
    tertiaryContainer: Color(0xFF1E3238),
    onTertiaryContainer: Color(0xFFD2E4E9),
    error: Color(0xFFD98A9C),
    onError: Color(0xFF3A1620),
    errorContainer: Color(0xFF43202A),
    onErrorContainer: Color(0xFFF6DCE2),
    surface: Color(0xFF131019),
    onSurface: Color(0xFFE7E3EF),
    onSurfaceVariant: Color(0xFFA49CB3),
    surfaceContainerLowest: Color(0xFF0E0B13),
    surfaceContainerLow: Color(0xFF1A1622),
    surfaceContainer: Color(0xFF211C2B),
    surfaceContainerHigh: Color(0xFF2A2436),
    surfaceContainerHighest: Color(0xFF332C41),
    outline: Color(0xFF38324A),
    outlineVariant: Color(0xFF2C2739),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE7E3EF),
    onInverseSurface: Color(0xFF1D1A24),
    inversePrimary: Color(0xFF6F5B97),
    surfaceTint: Color(0xFFB4A3D8),
  );
}