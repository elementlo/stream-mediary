/// M3U8 (HLS) playlist parser.
///
/// Supports:
/// - Master playlists (`#EXT-X-STREAM-INF`) with multi-level resolution
/// - Media playlists with `#EXTINF`, `#EXT-X-KEY` (AES-128/192/256),
///   `#EXT-X-MEDIA-SEQUENCE`, `#EXT-X-TARGETDURATION`, `#EXT-X-VERSION`,
///   `#EXT-X-DISCONTINUITY`, `#EXT-X-ENDLIST`
/// - Absolute and relative URL resolution against the playlist URL
library;

import 'attribute_parser.dart';
import 'playlist.dart';

/// Thrown when the input is not a valid m3u8 playlist.
class M3u8ParseException implements Exception {
  const M3u8ParseException(this.message);
  final String message;

  @override
  String toString() => 'M3u8ParseException: $message';
}

class M3u8Parser {
  const M3u8Parser();

  /// Parses [content] as an m3u8 playlist.
  ///
  /// [playlistUrl] is the absolute URL the content was fetched from; it is
  /// used to resolve relative segment/variant/key URIs.
  ParseResult parse(String content, {required String playlistUrl}) {
    final lines = content
        .split(RegExp(r'\r\n|\r|\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty || !lines.first.startsWith('#EXTM3U')) {
      throw const M3u8ParseException('Not an m3u8 playlist (missing #EXTM3U)');
    }

    // Detect master playlist by presence of STREAM-INF.
    final isMaster = lines.any((l) => l.startsWith('#EXT-X-STREAM-INF'));
    return isMaster
        ? _parseMaster(lines, playlistUrl)
        : _parseMedia(lines, playlistUrl);
  }

  MasterParseResult _parseMaster(List<String> lines, String baseUrl) {
    final variants = <Variant>[];
    Map<String, String>? pendingAttrs;

    for (final line in lines) {
      if (line.startsWith('#EXT-X-STREAM-INF')) {
        pendingAttrs = parseAttributeList(_tagValue(line));
      } else if (!line.startsWith('#') && pendingAttrs != null) {
        final attrs = pendingAttrs;
        pendingAttrs = null;
        final resolution = attrs['RESOLUTION'];
        variants.add(Variant(
          url: resolveUrl(line, baseUrl),
          bandwidth: int.tryParse(attrs['BANDWIDTH'] ?? ''),
          resolution: resolution,
          codecs: attrs['CODECS'],
          name: attrs['VIDEO-RANGE'] != null && resolution != null
              ? '$resolution (${attrs['VIDEO-RANGE']})'
              : null,
        ));
      }
    }

    if (variants.isEmpty) {
      throw const M3u8ParseException('Master playlist has no variants');
    }
    variants.sort((a, b) => (b.bandwidth ?? 0).compareTo(a.bandwidth ?? 0));
    return MasterParseResult(MasterPlaylist(variants: variants));
  }

  MediaParseResult _parseMedia(List<String> lines, String baseUrl) {
    final segments = <Segment>[];
    var mediaSequence = 0;
    var hasEndList = false;
    double? targetDuration;
    int? version;
    KeyInfo? currentKey;
    var pendingDiscontinuity = false;
    double? pendingDuration;

    for (final line in lines) {
      if (line.startsWith('#EXT-X-MEDIA-SEQUENCE')) {
        mediaSequence = int.tryParse(_tagValue(line) ?? '') ?? 0;
      } else if (line.startsWith('#EXT-X-TARGETDURATION')) {
        targetDuration = double.tryParse(_tagValue(line) ?? '');
      } else if (line.startsWith('#EXT-X-VERSION')) {
        version = int.tryParse(_tagValue(line) ?? '');
      } else if (line.startsWith('#EXT-X-ENDLIST')) {
        hasEndList = true;
      } else if (line.startsWith('#EXT-X-DISCONTINUITY')) {
        pendingDiscontinuity = true;
      } else if (line.startsWith('#EXT-X-KEY')) {
        currentKey = _parseKey(_tagValue(line), baseUrl);
      } else if (line.startsWith('#EXTINF')) {
        final value = _tagValue(line);
        final comma = value?.indexOf(',');
        final durationText =
            comma == null ? value : value!.substring(0, comma);
        pendingDuration = double.tryParse(durationText ?? '') ?? 0;
      } else if (!line.startsWith('#')) {
        // Segment URI line.
        segments.add(Segment(
          seq: mediaSequence + segments.length,
          url: resolveUrl(line, baseUrl),
          duration: pendingDuration ?? 0,
          keyInfo: currentKey?.encrypted == true ? currentKey : null,
          discontinuity: pendingDiscontinuity,
        ));
        pendingDuration = null;
        pendingDiscontinuity = false;
      }
    }

    if (segments.isEmpty) {
      throw const M3u8ParseException('Media playlist has no segments');
    }

    final totalDuration =
        segments.fold<double>(0, (sum, s) => sum + s.duration);

    return MediaParseResult(MediaPlaylist(
      segments: segments,
      totalDuration: totalDuration,
      mediaSequence: mediaSequence,
      isLive: !hasEndList,
      targetDuration: targetDuration,
      version: version,
    ));
  }

  KeyInfo? _parseKey(String? attrsRaw, String baseUrl) {
    final attrs = parseAttributeList(attrsRaw);
    final method = parseEncryptionMethod(attrs['METHOD']);
    if (method == EncryptionMethod.none) {
      // METHOD=NONE clears encryption for subsequent segments.
      return const KeyInfo(method: EncryptionMethod.none);
    }
    final uri = attrs['URI'];
    if (uri == null || uri.isEmpty) {
      throw const M3u8ParseException('EXT-X-KEY missing URI');
    }
    var ivHex = attrs['IV'];
    if (ivHex != null) {
      ivHex = ivHex.trim();
      if (ivHex.toLowerCase().startsWith('0x')) {
        ivHex = ivHex.substring(2);
      }
    }
    return KeyInfo(
      method: method,
      uri: resolveUrl(uri, baseUrl),
      ivHex: ivHex,
    );
  }

  /// Returns the value part of a `#TAG:value` line, or null.
  String? _tagValue(String line) {
    final idx = line.indexOf(':');
    if (idx == -1 || idx == line.length - 1) return null;
    return line.substring(idx + 1);
  }

  /// Resolves [url] against [baseUrl].
  ///
  /// Handles absolute URLs, protocol-relative URLs, absolute paths and
  /// relative paths (including `../` and query strings).
  static String resolveUrl(String url, String baseUrl) {
    final trimmed = url.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return trimmed;
    }

    final base = Uri.tryParse(baseUrl);
    if (base == null) return trimmed;

    if (trimmed.startsWith('//')) {
      return '${base.scheme}:$trimmed';
    }

    if (trimmed.startsWith('/')) {
      return base.replace(path: trimmed, query: null).toString();
    }

    // Relative path: resolve against the base directory.
    return base.resolve(trimmed).toString();
  }
}
