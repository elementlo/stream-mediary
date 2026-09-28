import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/platform/platform_profile.dart';
import 'core/platform/download_link_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/update/update_dialog.dart';
import 'providers/app_providers.dart';

class StreamMediaryApp extends ConsumerStatefulWidget {
  const StreamMediaryApp({super.key});

  @override
  ConsumerState<StreamMediaryApp> createState() => _StreamMediaryAppState();
}

class _StreamMediaryAppState extends ConsumerState<StreamMediaryApp> {
  /// One-shot guard: the board prefetch must fire exactly once per process,
  /// not on every rebuild of the app widget.
  static bool _boardPrefetchStarted = false;

  /// One-shot guard for the startup update check (same reasoning).
  static bool _updateCheckStarted = false;

  @override
  void initState() {
    super.initState();
    DownloadLinkService.instance.addListener(_openDownloadLink);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openDownloadLink());
  }

  @override
  void dispose() {
    DownloadLinkService.instance.removeListener(_openDownloadLink);
    super.dispose();
  }

  void _openDownloadLink() {
    final link = DownloadLinkService.instance.value;
    if (link == null || !mounted) return;
    DownloadLinkService.instance.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(routerProvider).go('/new', extra: link);
    });
  }

  /// Silently checks GitHub for a newer release shortly after startup and
  /// prompts once per version. Also drops stale update downloads.
  void _startUpdateCheck() {
    final service = ref.read(updateServiceProvider);
    service.cleanupStaleUpdates().ignore();
    // Delay so the check never competes with first-frame work or an
    // incoming download link.
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      final context = rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      checkAndPromptUpdate(context, ref, manual: false).ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
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

    if (!_updateCheckStarted && !Platform.isIOS) {
      _updateCheckStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startUpdateCheck();
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
