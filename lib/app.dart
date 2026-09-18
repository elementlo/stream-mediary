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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Resolved once: the platform cannot change while the app is running.
    final profile = PlatformProfile.resolve();

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
          final scale = MediaQuery.textScalerOf(context).clamp(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.4,
          );
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scale),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}