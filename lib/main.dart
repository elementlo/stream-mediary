import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit native libraries (must be called once).
  MediaKit.ensureInitialized();

  // Basic logging.
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: '
        '[${record.loggerName}] ${record.message}');
  });

  // Desktop window configuration.
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        minimumSize: Size(960, 600),
        size: Size(1120, 720),
        title: 'Stream Mediary',
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  runApp(const ProviderScope(child: StreamMediaryApp()));
}
