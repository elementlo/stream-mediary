import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

/// Reveals [filePath] in the platform file manager.
///
/// Desktop: opens the containing folder with the file selected (Finder /
/// Explorer / xdg-open). Mobile: opens the containing directory with the
/// system file handler (best effort — some Android file managers accept a
/// directory URI, iOS falls back to opening the file itself).
Future<void> revealInFileManager(String filePath) async {
  if (Platform.isMacOS) {
    await Process.run('open', ['-R', filePath]);
  } else if (Platform.isWindows) {
    await Process.run('explorer', ['/select,', filePath]);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', [p.dirname(filePath)]);
  } else {
    final dir = p.dirname(filePath);
    final result = await OpenFilex.open(dir);
    if (result.type != ResultType.done) {
      // Directory open unsupported: fall back to the file itself.
      await OpenFilex.open(filePath);
    }
  }
}
