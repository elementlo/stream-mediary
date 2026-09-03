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
  /// macOS do not inherit the shell PATH, so explicit probing is required.
  static const List<String> _candidatePaths = [
    'ffmpeg',
    '/opt/homebrew/bin/ffmpeg',
    '/usr/local/bin/ffmpeg',
    '/usr/bin/ffmpeg',
    '/opt/local/bin/ffmpeg',
  ];

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
  /// Returns the output `.mp4` file on success, or null when ffmpeg is
  /// unavailable or the remux fails (caller should keep the `.ts`).
  Future<File?> remuxToMp4(
    File inputTs, {
    String? ffmpegPath,
  }) async {
    final probeResult = await probe(userPath: ffmpegPath);
    if (!probeResult.available) return null;

    final outputPath = inputTs.path.replaceAll(RegExp(r'\.ts$'), '.mp4');
    final output = File(outputPath);

    try {
      final process = await Process.run(probeResult.path!, [
        '-y',
        '-i',
        inputTs.path,
        '-c',
        'copy',
        '-movflags',
        '+faststart',
        outputPath,
      ]);
      if (process.exitCode == 0 && output.existsSync() && output.lengthSync() > 0) {
        return output;
      }
    } on ProcessException {
      // Fall through to null.
    }

    // Clean up a partial output if any.
    if (output.existsSync()) {
      try {
        await output.delete();
      } on FileSystemException {
        // Ignore cleanup failures.
      }
    }
    return null;
  }
}
