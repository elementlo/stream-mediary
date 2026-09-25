import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

Future<File?> _openLogFile() async {
  try {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final file = File('${directory.path}/mediary.log');
    if (await file.exists() && await file.length() > 2 * 1024 * 1024) {
      final previous = File('${file.path}.old');
      if (await previous.exists()) await previous.delete();
      await file.rename(previous.path);
    }
    return file;
  } catch (_) {
    // Console logging remains available when the support directory is not.
    return null;
  }
}

void configureAppLogging() {
  Logger.root.level = Level.INFO;
  final file = _openLogFile();
  var pendingWrite = Future<void>.value();
  Logger.root.onRecord.listen((record) {
    final message =
        '${record.level.name}: ${record.time}: '
        '[${record.loggerName}] ${record.message}'
        '${record.error == null ? '' : '\n${record.error}'}'
        '${record.stackTrace == null ? '' : '\n${record.stackTrace}'}';
    // ignore: avoid_print
    print(message);
    pendingWrite = pendingWrite
        .then((_) async {
          final target = await file;
          if (target != null) {
            await target.writeAsString(
              '$message\n',
              mode: FileMode.append,
              flush: true,
            );
          }
        })
        .catchError((Object _) {
          // A log-write failure must never interrupt playback or downloads.
        });
  });
}
