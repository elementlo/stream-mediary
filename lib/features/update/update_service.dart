/// In-app update: check GitHub releases, download and install the package
/// for the current platform. iOS is intentionally unsupported.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/digests/sha256.dart';

import '../../core/utils/dio_proxy.dart';

final Logger _log = Logger('UpdateService');

/// GitHub repository (owner/name) whose releases are checked.
const String kUpdateRepo = 'elementlo/stream-mediary';

/// Raised for any user-facing update failure (network, checksum, install).
class UpdateException implements Exception {
  UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A available release plus the asset matching this platform.
class UpdateInfo {
  const UpdateInfo({
    required this.tagName,
    required this.version,
    required this.body,
    required this.assetName,
    required this.assetUrl,
    required this.assetSize,
    this.sha256,
  });

  final String tagName;
  final String version;
  final String body;
  final String assetName;
  final String assetUrl;
  final int assetSize;
  final String? sha256;
}

// ---------------------------------------------------------------------------
// Pure helpers (unit-testable without IO)
// ---------------------------------------------------------------------------

/// Parses a version string into numeric parts, stripping a leading `v`,
/// a `+build` suffix and a `-prerelease` suffix.
List<int> parseVersionParts(String version) {
  var s = version.trim();
  if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
  final plus = s.indexOf('+');
  if (plus >= 0) s = s.substring(0, plus);
  final dash = s.indexOf('-');
  if (dash >= 0) s = s.substring(0, dash);
  return s
      .split('.')
      .map((e) => int.tryParse(e.trim()) ?? 0)
      .toList();
}

/// True when [latest] is strictly newer than [current].
bool isNewerVersion(String latest, String current) {
  final a = parseVersionParts(latest);
  final b = parseVersionParts(current);
  final len = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < len; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// Picks the release asset name for [platform]/[arch] from [names].
///
/// Returns null when no suitable installer exists (e.g. iOS, or a release
/// that only ships source archives). Checksum files are ignored.
String? pickAssetName(
  List<String> names, {
  required String platform,
  required String arch,
}) {
  if (platform == 'ios') return null;
  for (final raw in names) {
    final n = raw.toLowerCase();
    if (!n.endsWith('.apk') && !n.endsWith('.zip')) continue;
    if (n.contains('sha256') || n.contains('sums')) continue;
    switch (platform) {
      case 'android':
        if (!n.contains('android')) continue;
        if (arch == 'arm64' && n.contains('arm64')) return raw;
        if (arch != 'arm64' && n.contains('armeabi-v7a')) return raw;
      case 'macos':
        if (!n.contains('macos')) continue;
        if (arch == 'arm64'
            ? n.contains('arm64')
            : (n.contains('x64') || n.contains('x86_64'))) {
          return raw;
        }
      case 'windows':
        if (!n.contains('windows')) continue;
        if (n.contains('x64') || n.contains('x86_64')) return raw;
    }
  }
  return null;
}

/// Extracts the lowercase hex sha256 from a GitHub asset `digest` field
/// (`sha256:<hex>`), or null when absent/malformed.
String? parseDigest(String? digest) {
  if (digest == null) return null;
  final idx = digest.indexOf(':');
  if (idx < 0) return null;
  final algo = digest.substring(0, idx).toLowerCase();
  if (algo != 'sha256') return null;
  final hex = digest.substring(idx + 1).trim().toLowerCase();
  return RegExp(r'^[0-9a-f]{64}$').hasMatch(hex) ? hex : null;
}

/// Computes the lowercase hex sha256 of [file] by streaming it.
Future<String> fileSha256(File file) async {
  final digest = SHA256Digest();
  await for (final chunk in file.openRead()) {
    final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
    digest.update(bytes, 0, bytes.length);
  }
  final out = Uint8List(digest.digestSize);
  digest.doFinal(out, 0);
  return out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class UpdateService {
  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String? _appliedProxy;

  /// Routes update-check and package-download traffic through the configured
  /// proxy (`host`/`port`), or restores a direct connection when [host] is
  /// blank. Shares the same semantics as the download engine's proxy.
  void updateProxy(String? host, int? port) {
    final proxy = normalizeProxy(host, port);
    if (proxy == _appliedProxy) return;
    _appliedProxy = proxy;
    applyDioProxy(_dio, proxy);
  }

  /// Detects the current platform key and CPU architecture.
  Future<(String, String)> detectPlatformArch() async {
    if (Platform.isAndroid) {
      var arch = 'arm64';
      try {
        final r = await Process.run('getprop', ['ro.product.cpu.abi']);
        final abi = (r.stdout as String).trim().toLowerCase();
        if (abi.contains('arm64')) {
          arch = 'arm64';
        } else if (abi.contains('armeabi')) {
          arch = 'armv7';
        } else if (abi.contains('x86_64')) {
          arch = 'x64';
        } else if (abi.contains('x86')) {
          arch = 'x86';
        }
      } catch (_) {
        // Keep the arm64 default.
      }
      return ('android', arch);
    }
    if (Platform.isMacOS) {
      var arch = 'arm64';
      try {
        final r = await Process.run('uname', ['-m']);
        final m = (r.stdout as String).trim().toLowerCase();
        arch = (m == 'arm64' || m == 'aarch64') ? 'arm64' : 'x64';
      } catch (_) {
        // Keep the arm64 default.
      }
      return ('macos', arch);
    }
    if (Platform.isWindows) return ('windows', 'x64');
    return ('ios', '');
  }

  /// Returns the latest release when it is newer than [currentVersion] and
  /// ships an installer for this platform; otherwise null.
  Future<UpdateInfo?> checkForUpdate(
    String currentVersion, {
    String? platform,
    String? arch,
  }) async {
    final (detectedPlatform, detectedArch) = await detectPlatformArch();
    final plat = platform ?? detectedPlatform;
    final a = arch ?? detectedArch;
    if (plat == 'ios') return null;

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.github.com/repos/$kUpdateRepo/releases/latest',
      options: Options(
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'stream-mediary-app',
        },
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    final data = response.data;
    if (data == null) return null;
    if (data['draft'] == true || data['prerelease'] == true) return null;

    final tagName = data['tag_name'] as String? ?? '';
    if (tagName.isEmpty) return null;
    if (!isNewerVersion(tagName, currentVersion)) return null;

    final assets = (data['assets'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final names = assets
        .map((e) => e['name'] as String? ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    final assetName = pickAssetName(names, platform: plat, arch: a);
    if (assetName == null) return null;

    final asset = assets.firstWhere((e) => e['name'] == assetName);
    final assetUrl = asset['browser_download_url'] as String? ?? '';
    if (assetUrl.isEmpty) return null;

    return UpdateInfo(
      tagName: tagName,
      version: tagName.startsWith('v') ? tagName.substring(1) : tagName,
      body: data['body'] as String? ?? '',
      assetName: assetName,
      assetUrl: assetUrl,
      assetSize: (asset['size'] as num?)?.toInt() ?? 0,
      sha256: parseDigest(asset['digest'] as String?),
    );
  }

  /// Directory holding downloaded update packages, one subfolder per version.
  Future<Directory> updatesDir() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'updates'));
  }

  /// Downloads [info]'s asset into [destDir], resuming a partial `.part`
  /// file when present, verifying integrity, and returning the final file.
  ///
  /// A previously completed and verified file is returned without re-download.
  /// Verification failure (a stale partial, or a proxy that mishandles the
  /// Range request) triggers one clean from-scratch retry before giving up.
  Future<File> downloadUpdate(
    UpdateInfo info, {
    required Directory destDir,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    await destDir.create(recursive: true);
    final finalFile = File(p.join(destDir.path, info.assetName));

    if (finalFile.existsSync()) {
      if (await _verify(finalFile, info)) return finalFile;
      // Corrupt complete file: remove and re-download from scratch.
      await finalFile.delete();
    }

    for (var attempt = 0;; attempt++) {
      final partFile = File('${finalFile.path}.part');
      final startByte =
          (attempt == 0 && partFile.existsSync()) ? partFile.lengthSync() : 0;

      await _transfer(info, partFile, startByte, onProgress, cancelToken);

      if (await _verify(partFile, info)) {
        await partFile.rename(finalFile.path);
        return finalFile;
      }
      _log.warning('update verification failed (attempt ${attempt + 1})');
      await _deleteQuietly(partFile);
      if (attempt >= 1) throw UpdateException('checksum');
    }
  }

  /// Streams the asset into [partFile], optionally resuming at [startByte].
  ///
  /// A proxy or CDN can error on connection teardown after every byte has
  /// arrived, so a non-cancel [DioException] from the stream is logged rather
  /// than thrown — [_verify] decides whether the file is actually usable.
  Future<void> _transfer(
    UpdateInfo info,
    File partFile,
    int startByte,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  ) async {
    final response = await _dio.get<ResponseBody>(
      info.assetUrl,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        receiveTimeout: const Duration(minutes: 10),
        headers: startByte > 0 ? {'Range': 'bytes=$startByte-'} : null,
      ),
      cancelToken: cancelToken,
    );

    final resumed = response.statusCode == 206 && startByte > 0;
    final contentLength =
        int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        ) ??
        0;
    final total = info.assetSize > 0
        ? info.assetSize
        : (resumed ? startByte + contentLength : contentLength);

    var received = resumed ? startByte : 0;
    final sink = partFile.openWrite(
      mode: resumed ? FileMode.append : FileMode.write,
    );
    try {
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      // A proxy or CDN can error on connection teardown after every byte has
      // arrived. Tolerate that only when the full body was received; a stream
      // that broke early is a real network failure and must surface as one.
      if (total > 0 && received < total) rethrow;
      _log.warning('update stream ended with error at $received/$total: $e');
    } finally {
      await sink.close();
    }
  }

  /// True when [file] matches the published sha256, or — when the release
  /// carries no digest — the declared asset size.
  Future<bool> _verify(File file, UpdateInfo info) async {
    if (!file.existsSync()) return false;
    if (info.sha256 != null) return await fileSha256(file) == info.sha256;
    return info.assetSize <= 0 || await file.length() == info.assetSize;
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      // Ignore.
    }
  }

  /// Installs a downloaded package using the platform-appropriate mechanism.
  ///
  /// - Android: hands the APK to the system installer.
  /// - macOS: unzips and reveals the new `.app` in Finder (sandbox forbids
  ///   self-replacement).
  /// - Windows: unzips, then runs a batch script that waits for this process
  ///   to exit, overwrites the install directory and relaunches; exits the app.
  Future<void> installUpdate(UpdateInfo info, File file) async {
    if (Platform.isAndroid) {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw UpdateException(result.message);
      }
      return;
    }
    if (Platform.isMacOS) {
      final extractDir = Directory(p.join(file.parent.path, 'extracted'));
      if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
      extractDir.createSync(recursive: true);
      // ditto preserves the .app bundle (symlinks, permissions).
      final r = await Process.run('ditto', [
        '-x',
        '-k',
        file.path,
        extractDir.path,
      ]);
      if (r.exitCode != 0) {
        throw UpdateException('unzip failed: ${r.stderr}');
      }
      final app = _findAppBundle(extractDir);
      if (app == null) throw UpdateException('app bundle not found');
      await Process.run('open', ['-R', app.path]);
      return;
    }
    if (Platform.isWindows) {
      await _installWindows(info, file);
      return;
    }
    throw UpdateException('unsupported platform');
  }

  Directory? _findAppBundle(Directory root) {
    for (final entity in root.listSync(recursive: true)) {
      if (entity is Directory && entity.path.endsWith('.app')) return entity;
    }
    return null;
  }

  Future<void> _installWindows(UpdateInfo info, File file) async {
    final staging = Directory(p.join(file.parent.path, 'extracted'));
    if (staging.existsSync()) staging.deleteSync(recursive: true);
    staging.createSync(recursive: true);
    // Windows 10+ ships bsdtar, which extracts zip archives.
    final r = await Process.run('tar', [
      '-xf',
      file.path,
      '-C',
      staging.path,
    ]);
    if (r.exitCode != 0) {
      throw UpdateException('unzip failed: ${r.stderr}');
    }

    // The archive may wrap everything in a single top-level folder; descend
    // into it so xcopy copies the exe/data directly.
    final sourceRoot = _flattenSingleDir(staging);

    final installDir = p.dirname(Platform.resolvedExecutable);
    final exeName = p.basename(Platform.resolvedExecutable);
    // Keep the script OUTSIDE sourceRoot so xcopy does not copy it into the
    // install directory.
    final bat = File(p.join(file.parent.path, 'mediary_update.bat'));
    // `ping` sleeps ~1s without needing an interactive console, unlike
    // `timeout`, which fails when the script runs detached (no console).
    //
    // Self-deletion must use the `(goto) 2>nul & del "%~f0"` idiom, not a bare
    // `del "%~f0"`: cmd reads a batch file line-by-line, so deleting it mid-run
    // makes cmd fail on the "next" line — it prints "找不到批处理文件" and leaves
    // the minimized console open. The relaunched app is a child of that console,
    // so closing the lingering window kills the app too. `(goto)` (no label)
    // ends the batch context first; cmd exits cleanly and the already-parsed
    // `del` on the same line still removes the script.
    final script = '''
@echo off
:wait
tasklist /FI "PID eq $pid" 2>nul | find "$pid" >nul
if not errorlevel 1 (
  ping -n 2 127.0.0.1 >nul
  goto wait
)
xcopy "${sourceRoot.path}\\*" "$installDir\\" /E /Y /I >nul
start "" "$installDir\\$exeName"
(goto) 2>nul & del "%~f0"
''';
    await bat.writeAsString(script, flush: true);
    // Launch the batch in its own MINIMIZED console via `start /min`. The
    // outer cmd runs detached (no console, returns immediately — so it cannot
    // deadlock on inherited stdout/stderr pipes), and `start /min` gives the
    // batch a single minimized console that its tasklist/ping/xcopy children
    // share. Launching the batch directly detached (DETACHED_PROCESS) would
    // leave it with no console, so every console child would allocate its own
    // window — flashing a new command prompt on each tick of the wait loop.
    await Process.start(
      'cmd',
      ['/c', 'start', '/min', '', bat.path],
      mode: ProcessStartMode.detached,
    );
    exit(0);
  }

  /// When [dir] holds exactly one subdirectory and no files, returns that
  /// subdirectory; otherwise returns [dir] unchanged.
  Directory _flattenSingleDir(Directory dir) {
    final entries = dir.listSync();
    if (entries.length == 1 && entries.single is Directory) {
      return entries.single as Directory;
    }
    return dir;
  }

  /// Removes stale update artifacts: version folders other than [keepVersion]
  /// and `.part` files older than 24h (a download interrupted by an app kill).
  Future<void> cleanupStaleUpdates({String? keepVersion}) async {
    try {
      final root = await updatesDir();
      if (!root.existsSync()) return;
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      for (final entity in root.listSync()) {
        if (entity is Directory) {
          if (keepVersion != null && p.basename(entity.path) == keepVersion) {
            continue;
          }
          try {
            entity.deleteSync(recursive: true);
          } on FileSystemException {
            // Ignore.
          }
        }
      }
      // Drop abandoned partial downloads regardless of version folder.
      for (final part in root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.part'))) {
        try {
          if (part.lastModifiedSync().isBefore(cutoff)) part.deleteSync();
        } on FileSystemException {
          // Ignore.
        }
      }
    } catch (e) {
      _log.warning('cleanupStaleUpdates failed: $e');
    }
  }
}
