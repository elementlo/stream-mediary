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
    this.refererUrl,
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

  /// Web page the stream was imported from (browser-extension deep link);
  /// null for manually added tasks.
  final String? refererUrl;

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

  /// Image-container extensions used to disguise a playlist (e.g. rou.video
  /// wraps HLS in a PNG/JPG). Their surrounding path segments are shared CDN
  /// infrastructure names, so we never walk up to a parent for these.
  static const Set<String> _imageExtensions = {
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
  };

  /// Strips a trailing playlist/disguise extension (and anything after it,
  /// such as a signature path) so the bare name can be inspected.
  static final RegExp _extensionStrip = RegExp(
    r'\.(m3u8|png|jpe?g|webp|gif).*$',
    caseSensitive: false,
  );

  static String _stripExtension(String name) =>
      name.replaceAll(_extensionStrip, '');

  /// True when [name]'s final extension is one of [exts].
  static bool _hasExtension(String name, Set<String> exts) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return false;
    return exts.contains(name.substring(dot + 1).toLowerCase());
  }

  String get effectiveTitle {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    final uri = Uri.tryParse(url);
    final segments = uri?.pathSegments ?? const [];

    // An image-disguised playlist (`.../cdn/master.png`, `.../index.jpg`)
    // carries no identifying information: its path segments are CDN
    // infrastructure names shared by every video on the host. Walking up to a
    // parent directory would give every disguised download the same title, so
    // when the file's own name is generic we fall straight through to a unique
    // name instead of walking up.
    final last = segments.isEmpty ? '' : segments.last;
    final disguised = _hasExtension(last, _imageExtensions);

    if (!disguised) {
      // Walk from the last segment upwards, skipping generic playlist names,
      // so `.../my-show/index.m3u8` yields `my-show` instead of `index`.
      for (var i = segments.length - 1; i >= 0; i--) {
        var name = segments[i];
        if (name.isEmpty) continue;
        name = _stripExtension(name);
        if (name.isEmpty || _genericNames.contains(name.toLowerCase())) {
          continue;
        }
        return name;
      }
    } else {
      // Use the disguised file's own name when it is meaningful
      // (`episode01.png` -> `episode01`); otherwise fall through. A generic
      // own name (`index.jpg`, `master.png`) must NOT be returned verbatim,
      // or every such download collides on the same default title.
      final name = _stripExtension(last);
      if (name.isNotEmpty && !_genericNames.contains(name.toLowerCase())) {
        return name;
      }
    }

    // No meaningful path segment (or a disguise): build a unique host +
    // timestamp name so concurrent downloads never collide on a default.
    final host = uri?.host;
    final stamp = _uniqueStamp();
    if (host != null && host.isNotEmpty) return '$host-$stamp';
    return 'mediary-$stamp';
  }

  /// Monotonic counter appended to the timestamp so two disguised downloads
  /// created within the same second still get distinct default titles.
  static int _stampCounter = 0;

  static String _uniqueStamp() {
    final t = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final seq = (_stampCounter++ % 100).toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}'
        '-${two(t.hour)}${two(t.minute)}${two(t.second)}$seq';
  }
}

/// Engine-wide tunables, sourced from settings.
class EngineConfig {
  const EngineConfig({
    this.taskConcurrency = 3,
    this.segmentConcurrency = 16,
    this.preferMp4 = true,
    this.ffmpegPath,
    this.proxyHost,
    this.proxyPort,
  });

  /// Maximum number of tasks downloading simultaneously.
  final int taskConcurrency;

  /// Segments downloaded concurrently within a task.
  final int segmentConcurrency;

  /// When true and ffmpeg is available, remux merged output to mp4.
  final bool preferMp4;

  /// Optional explicit ffmpeg binary path.
  final String? ffmpegPath;

  /// Optional HTTP proxy host for all download traffic. An empty or null
  /// value means "no proxy" (direct connections).
  final String? proxyHost;

  /// Port of [proxyHost]; ignored when no proxy host is set.
  final int? proxyPort;

  /// True when a usable proxy host is configured.
  bool get hasProxy => proxyHost != null && proxyHost!.trim().isNotEmpty;

  EngineConfig copyWith({
    int? taskConcurrency,
    int? segmentConcurrency,
    bool? preferMp4,
    String? ffmpegPath,
    String? proxyHost,
    int? proxyPort,
  }) => EngineConfig(
    taskConcurrency: taskConcurrency ?? this.taskConcurrency,
    segmentConcurrency: segmentConcurrency ?? this.segmentConcurrency,
    preferMp4: preferMp4 ?? this.preferMp4,
    ffmpegPath: ffmpegPath ?? this.ffmpegPath,
    proxyHost: proxyHost ?? this.proxyHost,
    proxyPort: proxyPort ?? this.proxyPort,
  );
}
