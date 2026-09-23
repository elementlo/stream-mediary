/// Configuration and request models for the download engine.
library;

/// User-supplied options attached to a new download.
class DownloadRequest {
  const DownloadRequest({
    required this.url,
    this.title,
    this.headers = const {},
    this.customKeyHex,
    this.customIvHex,
    this.saveDir,
    this.variantUrl,
    this.sourceUrl,
  });

  /// The m3u8 URL (or the chosen variant URL for master playlists).
  final String url;

  /// Display title; defaults to the last path segment of [url].
  final String? title;

  /// Custom HTTP headers attached to every request.
  final Map<String, String> headers;

  /// Optional user override for the AES key (hex).
  final String? customKeyHex;

  /// Optional user override for the AES IV (hex).
  final String? customIvHex;

  /// Directory to store segments and output; null uses the default.
  final String? saveDir;

  /// When the source is a master playlist, the selected variant URL.
  final String? variantUrl;
  final String? sourceUrl;

  /// Generic playlist file names that carry no identifying information.
  /// When the last path segment is one of these, the parent directory name
  /// is used instead (e.g. `.../my-show/index.m3u8` -> `my-show`).
  static const Set<String> _genericNames = {
    'index',
    'master',
    'media',
    'playlist',
    'main',
    'stream',
    'video',
    'hls',
    'manifest',
    'play',
    'player',
  };

  String get effectiveTitle {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    final uri = Uri.tryParse(url);
    final segments = uri?.pathSegments ?? const [];
    // Walk from the last segment upwards, skipping generic playlist names,
    // so `.../my-show/index.m3u8` yields `my-show` instead of `index`.
    for (var i = segments.length - 1; i >= 0; i--) {
      var name = segments[i];
      if (name.isEmpty) continue;
      name = name.replaceAll(RegExp(r'\.m3u8.*$'), '');
      if (name.isEmpty || _genericNames.contains(name.toLowerCase())) {
        continue;
      }
      return name;
    }
    // No meaningful path segment: fall back to the host, then the raw URL.
    final host = uri?.host;
    if (host != null && host.isNotEmpty) return host;
    return url;
  }
}

/// Engine-wide tunables, sourced from settings.
class EngineConfig {
  const EngineConfig({
    this.taskConcurrency = 3,
    this.segmentConcurrency = 8,
    this.preferMp4 = true,
    this.ffmpegPath,
  });

  /// Maximum number of tasks downloading simultaneously.
  final int taskConcurrency;

  /// Segments downloaded concurrently within a task.
  final int segmentConcurrency;

  /// When true and ffmpeg is available, remux merged output to mp4.
  final bool preferMp4;

  /// Optional explicit ffmpeg binary path.
  final String? ffmpegPath;

  EngineConfig copyWith({
    int? taskConcurrency,
    int? segmentConcurrency,
    bool? preferMp4,
    String? ffmpegPath,
  }) => EngineConfig(
    taskConcurrency: taskConcurrency ?? this.taskConcurrency,
    segmentConcurrency: segmentConcurrency ?? this.segmentConcurrency,
    preferMp4: preferMp4 ?? this.preferMp4,
    ffmpegPath: ffmpegPath ?? this.ffmpegPath,
  );
}
