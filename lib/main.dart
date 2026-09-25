import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/platform/download_link_service.dart';
import 'core/utils/app_logging.dart';

Future<void> main([List<String> arguments = const []]) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureAppLogging();
  await DownloadLinkService.instance.initialize(arguments: arguments);

  // media_kit native libraries are loaded lazily on first Player creation
  // (see playerProvider) to keep cold start fast.

  // Desktop window configuration.
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        minimumSize: Size(960, 600),
        size: Size(1120, 720),
        title: 'Mediary',
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  runApp(const ProviderScope(child: StreamMediaryApp()));
}
