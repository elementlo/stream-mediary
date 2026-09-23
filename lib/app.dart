import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/platform/platform_profile.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';

class StreamMediaryApp extends ConsumerWidget {
  const StreamMediaryApp({super.key});

  /// One-shot guard: the board prefetch must fire exactly once per process,
  /// not on every rebuild of the app widget.
  static bool _boardPrefetchStarted = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(queuePolicyProvider);
    ref.watch(completionNotificationsProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Resolved once: the platform cannot change while the app is running.
    final profile = PlatformProfile.resolve();

    // Warm the board cache right after the first frame so opening the board
    // later renders instantly even on a cold install. Errors are swallowed
    // here; the board page surfaces them when the user actually visits.
    if (!_boardPrefetchStarted) {
      _boardPrefetchStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(boardPrefetchProvider.future).ignore();
      });
    }

    return PlatformScope(
      profile: profile,
      child: MaterialApp.router(
        title: 'Mediary',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(profile: profile),
        darkTheme: AppTheme.dark(profile: profile),
        themeMode: themeMode,
        routerConfig: router,
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          // Clamp text scaling to a range the layout still holds at. The
          // signature segment bar and metric rows are the tightest spots.
          final scale = MediaQuery.textScalerOf(context)
              .clamp(minScaleFactor: 0.85, maxScaleFactor: 1.4);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scale),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
