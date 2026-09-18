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

  static const MediaryColors light = MediaryColors(
    success: Color(0xFF059669),
    successContainer: Color(0xFFD7F2E4),
    onSuccessContainer: Color(0xFF04382A),
    warning: Color(0xFFD97706),
    warningContainer: Color(0xFFFDF0D5),
    accent: Color(0xFF0891B2),
    accentContainer: Color(0xFFD3EFF6),
    danger: Color(0xFFE11D48),
    dangerContainer: Color(0xFFFDE2E8),
    hairline: Color(0xFFDDE1E9),
    track: Color(0xFFE9ECF2),
    doneSegment: Color(0xFF4F46E5),
  );

  static const MediaryColors dark = MediaryColors(
    success: Color(0xFF34D399),
    successContainer: Color(0xFF0E3B2E),
    onSuccessContainer: Color(0xFFB7F5DA),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF3D2E0B),
    accent: Color(0xFF22D3EE),
    accentContainer: Color(0xFF0C3A47),
    danger: Color(0xFFFB7185),
    dangerContainer: Color(0xFF431B25),
    hairline: Color(0xFF333A47),
    track: Color(0xFF2A3140),
    doneSegment: Color(0xFF7C8CFF),
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
/// are tuned by hand, and the brand indigo matches the launcher icon
/// (`#4F46E5`) so icon and UI read as one product.
abstract final class MediaryPalette {
  /// Brand indigo — launcher icon background.
  static const Color brand = Color(0xFF4F46E5);

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: brand,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE8E9FE),
    onPrimaryContainer: Color(0xFF1B1D5E),
    secondary: Color(0xFF5C6577),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFECEEF3),
    onSecondaryContainer: Color(0xFF2A2F3A),
    tertiary: Color(0xFF0891B2),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD3EFF6),
    onTertiaryContainer: Color(0xFF05303C),
    error: Color(0xFFE11D48),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFDE2E8),
    onErrorContainer: Color(0xFF4A0719),
    surface: Color(0xFFF7F8FA),
    onSurface: Color(0xFF14171F),
    onSurfaceVariant: Color(0xFF5C6577),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF1F3F7),
    surfaceContainerHigh: Color(0xFFE9ECF2),
    surfaceContainerHighest: Color(0xFFE2E6ED),
    outline: Color(0xFFDDE1E9),
    outlineVariant: Color(0xFFE9ECF2),
    shadow: Color(0xFF0B1020),
    scrim: Color(0xFF0B1020),
    inverseSurface: Color(0xFF22262F),
    onInverseSurface: Color(0xFFF4F5F8),
    inversePrimary: Color(0xFF9BA6FF),
    surfaceTint: brand,
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7C8CFF),
    onPrimary: Color(0xFF0B1020),
    primaryContainer: Color(0xFF2A3170),
    onPrimaryContainer: Color(0xFFDDE0FF),
    secondary: Color(0xFF9BA3B4),
    onSecondary: Color(0xFF161A22),
    secondaryContainer: Color(0xFF262C38),
    onSecondaryContainer: Color(0xFFD5D9E3),
    tertiary: Color(0xFF22D3EE),
    onTertiary: Color(0xFF04252E),
    tertiaryContainer: Color(0xFF0C3A47),
    onTertiaryContainer: Color(0xFFB6EDF8),
    error: Color(0xFFFB7185),
    onError: Color(0xFF3B0A16),
    errorContainer: Color(0xFF431B25),
    onErrorContainer: Color(0xFFFFD9DF),
    surface: Color(0xFF0F1116),
    onSurface: Color(0xFFE8EAF0),
    onSurfaceVariant: Color(0xFF9BA3B4),
    surfaceContainerLowest: Color(0xFF0B0D12),
    surfaceContainerLow: Color(0xFF15181F),
    surfaceContainer: Color(0xFF1A1E27),
    surfaceContainerHigh: Color(0xFF222732),
    surfaceContainerHighest: Color(0xFF2A3040),
    outline: Color(0xFF333A47),
    outlineVariant: Color(0xFF252B36),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE8EAF0),
    onInverseSurface: Color(0xFF14171F),
    inversePrimary: Color(0xFF4F46E5),
    surfaceTint: Color(0xFF7C8CFF),
  );
}