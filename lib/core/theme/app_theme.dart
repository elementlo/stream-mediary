import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../platform/platform_profile.dart';
import 'design_tokens.dart';
import 'mediary_colors.dart';

/// Application theming.
///
/// Built from the hand-authored [MediaryPalette] rather than a seed color, and
/// configured so that every component defaults to Mediary's own look (flat
/// surfaces, hairline borders, three-tier radii) instead of Material defaults.
abstract final class AppTheme {
  static ThemeData light({PlatformProfile? profile}) =>
      _build(MediaryPalette.light, MediaryColors.light, profile);

  static ThemeData dark({PlatformProfile? profile}) =>
      _build(MediaryPalette.dark, MediaryColors.dark, profile);

  static ThemeData _build(
    ColorScheme scheme,
    MediaryColors colors,
    PlatformProfile? profile,
  ) {
    final density = profile?.density ?? VisualDensity.standard;
    final text = _textTheme(scheme);

    // Navigation label size per platform convention:
    // - Material 3 (mobile): labelMedium = 12sp
    // - Apple HIG (macOS sidebar): 13pt minimum
    // - Fluent (Windows nav): 14px
    // Desktop settles on 13.5 — readable on both, not chunky on macOS.
    final isDesktop = profile?.isDesktop ?? false;
    final navLabelSize = isDesktop ? 13.5 : 12.0;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      visualDensity: density,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,

      // Flat surfaces: layering comes from surface steps + hairlines, never
      // from elevation. Only FABs, sheets and menus cast a shadow.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: BorderSide(color: colors.hairline, width: 1)),
      ),

      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgAll,
          side: BorderSide(color: colors.hairline, width: 1),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colors.hairline,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md + 2,
          vertical: Spacing.md + 1,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle:
            text.bodySmall?.copyWith(color: scheme.primary, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: colors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: colors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(0, profile?.minTapTarget ?? TapTarget.touch),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
          textStyle: text.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, profile?.minTapTarget ?? TapTarget.touch),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: colors.hairline),
          shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
          textStyle: text.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: Size(0, profile?.minTapTarget ?? TapTarget.touch),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          shape: RoundedRectangleBorder(borderRadius: Radii.smAll),
          textStyle: text.labelLarge,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          minimumSize: Size.square(profile?.minTapTarget ?? TapTarget.touch),
          shape: RoundedRectangleBorder(borderRadius: Radii.smAll),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: Radii.lgAll),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontSize: navLabelSize,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 20),
        unselectedIconTheme:
            IconThemeData(color: scheme.onSurfaceVariant, size: 20),
        selectedLabelTextStyle: text.labelMedium
            ?.copyWith(fontSize: navLabelSize, color: scheme.primary),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(
            fontSize: navLabelSize, color: scheme.onSurfaceVariant),
      ),

      listTileTheme: ListTileThemeData(
        minVerticalPadding: Spacing.sm,
        minTileHeight: profile?.listItemHeight ?? 56,
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        side: BorderSide.none,
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        shape: const StadiumBorder(),
      ),

      // Material's default unselected switch pairs an `outline` thumb with a
      // `surfaceContainerHighest` track — nearly identical in this palette,
      // so the control looks invisible. Use a high-contrast gray thumb and
      // a hairline-bordered track for the off state instead.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : colors.hairline,
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          side: WidgetStatePropertyAll(BorderSide(color: colors.hairline)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Radii.mdAll),
          ),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: colors.track,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: colors.track,
        linearMinHeight: 6,
        circularTrackColor: colors.track,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: profile?.isDesktop ?? false
            ? SnackBarBehavior.floating
            : SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        elevation: 3,
        insetPadding: const EdgeInsets.all(Spacing.lg),
        shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: Radii.xlAll),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
        textStyle: text.bodyMedium,
      ),

      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: scheme.surfaceContainer,
        collapsedBackgroundColor: scheme.surfaceContainer,
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
        collapsedShape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
        tilePadding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          0,
          Spacing.lg,
          Spacing.lg,
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
        thumbColor: WidgetStatePropertyAll(
          scheme.onSurfaceVariant.withValues(alpha: 0.35),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: Radii.smAll,
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs + 2,
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.24),
        selectionHandleColor: scheme.primary,
      ),

      pageTransitionsTheme: _pageTransitions(profile),
    );
  }

  /// Platform-native page transitions.
  static PageTransitionsTheme _pageTransitions(PlatformProfile? profile) {
    if (profile?.useCupertinoPageTransition ?? false) {
      return const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      );
    }
    // Desktop gets a restrained fade-and-rise; mobile keeps the M3 default.
    const fadeUp = _FadeUpPageTransitionsBuilder();
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.macOS: fadeUp,
        TargetPlatform.windows: fadeUp,
        TargetPlatform.linux: fadeUp,
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    );
  }

  /// Type scale with tabular figures on the numeric styles.
  ///
  /// Line heights are ~8% taller than Material's defaults so Chinese glyphs
  /// do not feel cramped.
  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.39,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 1.47,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
        fontFeatures: tabularFigures,
      ),
      titleSmall: TextStyle(
        fontSize: 12.5,
        height: 1.44,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 1.53,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        height: 1.56,
        color: scheme.onSurface,
        fontFeatures: tabularFigures,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.5,
        letterSpacing: 0.1,
        color: scheme.onSurfaceVariant,
        fontFeatures: tabularFigures,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 11.5,
        height: 1.39,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.36,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: scheme.onSurfaceVariant,
        fontFeatures: tabularFigures,
      ),
    );
  }
}

/// Desktop page transition: a short fade with a small upward rise.
///
/// Feels like a native window content swap rather than a mobile push.
class _FadeUpPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeUpPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.enter,
      reverseCurve: Motion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.012),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}