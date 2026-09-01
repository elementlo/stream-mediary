/// M3U8 (HLS) playlist data models.
///
/// Pure Dart models shared by the parser, the download engine and the UI.
library;

/// Encryption method declared by an `EXT-X-KEY` tag.
enum EncryptionMethod { none, aes128, aes192, aes256 }

extension EncryptionMethodX on EncryptionMethod {
  int get keyBytes => switch (this) {
        EncryptionMethod.aes128 => 16,
        EncryptionMethod.aes192 => 24,
        EncryptionMethod.aes256 => 32,
        EncryptionMethod.none => 0,
      };

  String get label => switch (this) {
        EncryptionMethod.none => 'NONE',
        EncryptionMethod.aes128 => 'AES-128',
        EncryptionMethod.aes192 => 'AES-192',
        EncryptionMethod.aes256 => 'AES-256',
      };
}

/// Parses an `EncryptionMethod` from the METHOD attribute value.
EncryptionMethod parseEncryptionMethod(String? value) => switch (value) {
      'AES-128' => EncryptionMethod.aes128,
      'AES-192' => EncryptionMethod.aes192,
      'AES-256' => EncryptionMethod.aes256,
      _ => EncryptionMethod.none,
    };

/// Encryption information bound to a range of segments.
class KeyInfo {
  const KeyInfo({
    required this.method,
    this.uri,
    this.ivHex,
  });

  final EncryptionMethod method;

  /// Absolute or playlist-relative URI of the key file.
  final String? uri;

  /// Explicit IV from the playlist as a hex string (without 0x prefix
  /// normalized by the parser), or null when the IV defaults to the
  /// segment media sequence number.
  final String? ivHex;

  bool get encrypted => method != EncryptionMethod.none;

  Map<String, dynamic> toJson() => {
        'method': method.name,
        'uri': uri,
        'ivHex': ivHex,
      };

  factory KeyInfo.fromJson(Map<String, dynamic> json) => KeyInfo(
        method: EncryptionMethod.values.firstWhere(
          (m) => m.name == json['method'],
          orElse: () => EncryptionMethod.none,
        ),
        uri: json['uri'] as String?,
        ivHex: json['ivHex'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is KeyInfo &&
      other.method == method &&
      other.uri == uri &&
      other.ivHex == ivHex;

  @override
  int get hashCode => Object.hash(method, uri, ivHex);
}

/// A single media segment (`#EXTINF` + URI line).
class Segment {
  const Segment({
    required this.seq,
    required this.url,
    required this.duration,
    this.keyInfo,
    this.discontinuity = false,
  });

  /// Media sequence number of this segment within the playlist.
  final int seq;

  /// Resolved absolute URL of the segment.
  final String url;

  /// Segment duration in seconds from `#EXTINF`.
  final double duration;

  /// Encryption info in effect for this segment (null when unencrypted).
  final KeyInfo? keyInfo;

  /// Whether an `EXT-X-DISCONTINUITY` tag precedes this segment.
  final bool discontinuity;

  Map<String, dynamic> toJson() => {
        'seq': seq,
        'url': url,
        'duration': duration,
        'keyInfo': keyInfo?.toJson(),
        'discontinuity': discontinuity,
      };

  factory Segment.fromJson(Map<String, dynamic> json) => Segment(
        seq: json['seq'] as int,
        url: json['url'] as String,
        duration: (json['duration'] as num).toDouble(),
        keyInfo: json['keyInfo'] == null
            ? null
            : KeyInfo.fromJson(json['keyInfo'] as Map<String, dynamic>),
        discontinuity: json['discontinuity'] as bool? ?? false,
      );
}

/// A media playlist (`#EXTM3U` containing segments).
class MediaPlaylist {
  const MediaPlaylist({
    required this.segments,
    required this.totalDuration,
    required this.mediaSequence,
    this.isLive = false,
    this.targetDuration,
    this.version,
  });

  final List<Segment> segments;

  /// Sum of segment durations in seconds.
  final double totalDuration;

  /// Value of `#EXT-X-MEDIA-SEQUENCE` (defaults to 0).
  final int mediaSequence;

  /// True when the playlist lacks `#EXT-X-ENDLIST` (live stream).
  final bool isLive;

  final double? targetDuration;

  final int? version;

  int get segmentCount => segments.length;

  bool get encrypted => segments.any((s) => s.keyInfo?.encrypted ?? false);

  bool get hasDiscontinuity => segments.any((s) => s.discontinuity);

  Map<String, dynamic> toJson() => {
        'segments': segments.map((s) => s.toJson()).toList(),
        'totalDuration': totalDuration,
        'mediaSequence': mediaSequence,
        'isLive': isLive,
        'targetDuration': targetDuration,
        'version': version,
      };

  factory MediaPlaylist.fromJson(Map<String, dynamic> json) => MediaPlaylist(
        segments: (json['segments'] as List)
            .map((e) => Segment.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalDuration: (json['totalDuration'] as num).toDouble(),
        mediaSequence: json['mediaSequence'] as int,
        isLive: json['isLive'] as bool? ?? false,
        targetDuration: (json['targetDuration'] as num?)?.toDouble(),
        version: json['version'] as int?,
      );
}

/// A variant stream entry inside a master playlist.
class Variant {
  const Variant({
    required this.url,
    this.bandwidth,
    this.resolution,
    this.codecs,
    this.name,
  });

  /// Resolved absolute URL of the variant media playlist.
  final String url;

  final int? bandwidth;

  /// e.g. "1920x1080".
  final String? resolution;

  final String? codecs;

  /// Optional human-readable label (from NAME attribute when present).
  final String? name;

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    final parts = <String>[];
    if (resolution != null) parts.add(resolution!);
    if (bandwidth != null) parts.add('${(bandwidth! / 1000).round()} kbps');
    return parts.isEmpty ? url : parts.join(' · ');
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'bandwidth': bandwidth,
        'resolution': resolution,
        'codecs': codecs,
        'name': name,
      };

  factory Variant.fromJson(Map<String, dynamic> json) => Variant(
        url: json['url'] as String,
        bandwidth: json['bandwidth'] as int?,
        resolution: json['resolution'] as String?,
        codecs: json['codecs'] as String?,
        name: json['name'] as String?,
      );
}

/// A master playlist (`#EXT-X-STREAM-INF` entries).
class MasterPlaylist {
  const MasterPlaylist({required this.variants});

  /// Variants sorted by bandwidth descending (highest quality first).
  final List<Variant> variants;

  Map<String, dynamic> toJson() => {
        'variants': variants.map((v) => v.toJson()).toList(),
      };

  factory MasterPlaylist.fromJson(Map<String, dynamic> json) =>
      MasterPlaylist(
        variants: (json['variants'] as List)
            .map((e) => Variant.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Result of parsing an m3u8 document: either a master or a media playlist.
sealed class ParseResult {
  const ParseResult();
}

class MasterParseResult extends ParseResult {
  const MasterParseResult(this.master);
  final MasterPlaylist master;
}

class MediaParseResult extends ParseResult {
  const MediaParseResult(this.media);
  final MediaPlaylist media;
}
