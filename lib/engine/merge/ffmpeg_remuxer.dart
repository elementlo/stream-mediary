/// Optional ffmpeg-based lossless remuxing.
///
/// Detects a usable `ffmpeg` binary (PATH plus common install locations and a
/// user-supplied path) and remuxes a merged `.ts` file into `.mp4` with
/// `-c copy` (no re-encode). Falls back gracefully when ffmpeg is absent or
/// the remux fails.
library;

import 'dart:io';

/// Result of probing for an ffmpeg binary.
class FfmpegProbeResult {
  const FfmpegProbeResult({required this.available, this.path, this.version});

  final bool available;

  /// Absolute path of the usable ffmpeg binary, when available.
  final String? path;

  /// Version string reported by `ffmpeg -version`, when available.
  final String? version;
}

class FfmpegRemuxer {
  const FfmpegRemuxer();

  /// Common locations probed in addition to the process PATH. GUI apps on
  /// macOS do not inherit the shell PATH, and Windows GUI apps only see the
  /// system PATH snapshot captured at process creation, so explicit probing of
  /// well-known install locations is required on both.
  static const List<String> _unixCandidatePaths = [
    'ffmpeg',
    '/opt/homebrew/bin/ffmpeg',
    '/usr/local/bin/ffmpeg',
    '/usr/bin/ffmpeg',
    '/opt/local/bin/ffmpeg',
  ];

  /// Windows candidates. The bare `ffmpeg` entry resolves `ffmpeg.exe` via
  /// PATH; the rest cover popular manual-install and package-manager layouts.
  static const List<String> _windowsCandidatePaths = [
    'ffmpeg',
    r'C:\ffmpeg\bin\ffmpeg.exe',
    r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
    r'C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe',
    r'C:\ProgramData\chocolatey\bin\ffmpeg.exe',
    r'C:\tools\ffmpeg\bin\ffmpeg.exe',
  ];

  static List<String> get _candidatePaths =>
      Platform.isWindows ? _windowsCandidatePaths : _unixCandidatePaths;

  /// Windows paths that live under the user profile and therefore depend on
  /// environment variables (scoop, winget). Resolved lazily; empty elsewhere.
  static List<String> _userScopedWindowsPaths() {
    if (!Platform.isWindows) return const [];
    final result = <String>[];
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.isNotEmpty) {
      // scoop installs shims here; winget links land under AppData\Local.
      result.add('$userProfile\\scoop\\shims\\ffmpeg.exe');
      result.add(
        '$userProfile\\AppData\\Local\\Microsoft\\WinGet\\Links\\ffmpeg.exe',
      );
    }
    return result;
  }

  /// Probes for a usable ffmpeg binary.
  ///
  /// [userPath], when provided, is tried first. On mobile platforms ffmpeg is
  /// not expected to be installed, so probing (which forks a process per
  /// candidate) is skipped entirely to avoid UI stalls.
  Future<FfmpegProbeResult> probe({String? userPath}) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return const FfmpegProbeResult(available: false);
    }

    final candidates = <String>[
      if (userPath != null && userPath.trim().isNotEmpty) userPath.trim(),
      ..._candidatePaths,
      ..._userScopedWindowsPaths(),
    ];

    for (final candidate in candidates) {
      final result = await _tryVersion(candidate);
      if (result != null) {
        return FfmpegProbeResult(
          available: true,
          path: candidate,
          version: result,
        );
      }
    }
    return const FfmpegProbeResult(available: false);
  }

  Future<String?> _tryVersion(String binary) async {
    try {
      final process = await Process.run(binary, ['-version']);
      if (process.exitCode == 0) {
        final out = process.stdout.toString();
        final firstLine = out.split('\n').first.trim();
        return firstLine.isEmpty ? 'unknown' : firstLine;
      }
    } on ProcessException {
      // Binary not found; try next candidate.
    }
    return null;
  }

  /// Remuxes [inputTs] into a sibling `.mp4` using `-c copy`.
  ///
  /// Self-healing: when the strict remux fails (corrupt or truncated TS
  /// data), retries once with error detection relaxed
  /// (`-err_detect ignore_err`), which lets ffmpeg skip bad packets and
  /// still produce a playable file.
  ///
  /// Returns the output `.mp4` file on success, or null when ffmpeg is
  /// unavailable or both attempts fail (caller should keep the `.ts`).
  Future<File?> remuxToMp4(
    File inputTs, {
    String? ffmpegPath,
  }) async {
    final probeResult = await probe(userPath: ffmpegPath);
    if (!probeResult.available) return null;

    final outputPath = inputTs.path.replaceAll(RegExp(r'\.ts$'), '.mp4');
    final output = File(outputPath);

    // Attempt 1: strict lossless copy. Attempt 2: tolerate corrupt packets.
    final attempts = <List<String>>[
      [
        '-y',
        '-i', inputTs.path,
        '-c', 'copy',
        '-movflags', '+faststart',
        outputPath,
      ],
      [
        '-y',
        '-err_detect', 'ignore_err',
        '-i', inputTs.path,
        '-c', 'copy',
        '-movflags', '+faststart',
        outputPath,
      ],
    ];

    for (final args in attempts) {
      try {
        final process = await Process.run(probeResult.path!, args);
        if (process.exitCode == 0 &&
            output.existsSync() &&
            output.lengthSync() > 0) {
          return output;
        }
      } on ProcessException {
        // Fall through to the next attempt / null.
      }
      // Clean up a partial output before retrying.
      if (output.existsSync()) {
        try {
          await output.delete();
        } on FileSystemException {
          // Ignore cleanup failures.
        }
      }
    }
    return null;
  }
}
