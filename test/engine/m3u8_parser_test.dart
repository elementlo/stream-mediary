import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/m3u8/m3u8_parser.dart';
import 'package:stream_mediary/engine/m3u8/playlist.dart';

void main() {
  const parser = M3u8Parser();
  const baseUrl = 'https://cdn.example.com/video/index.m3u8';

  group('media playlist parsing', () {
    test('parses basic VOD playlist with EXTINF and ENDLIST', () {
      const content = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
#EXTINF:9.5,
seg0.ts
#EXTINF:10.0,
seg1.ts
#EXTINF:8.25,
seg2.ts
#EXT-X-ENDLIST
''';
      final result = parser.parse(content, playlistUrl: baseUrl);
      expect(result, isA<MediaParseResult>());
      final media = (result as MediaParseResult).media;

      expect(media.segmentCount, 3);
      expect(media.isLive, isFalse);
      expect(media.targetDuration, 10);
      expect(media.version, 3);
      expect(media.totalDuration, closeTo(27.75, 0.001));
      expect(media.segments[0].seq, 0);
      expect(media.segments[0].duration, 9.5);
      expect(media.segments[0].url,
          'https://cdn.example.com/video/seg0.ts');
    });

    test('resolves relative, absolute-path and absolute URLs', () {
      const content = '''
#EXTM3U
#EXTINF:10,
relative/seg0.ts
#EXTINF:10,
/abs/seg1.ts
#EXTINF:10,
https://other.example.com/seg2.ts
#EXT-X-ENDLIST
''';
      final media =
          (parser.parse(content, playlistUrl: baseUrl) as MediaParseResult)
              .media;

      expect(media.segments[0].url,
          'https://cdn.example.com/video/relative/seg0.ts');
      expect(media.segments[1].url, 'https://cdn.example.com/abs/seg1.ts');
      expect(media.segments[2].url, 'https://other.example.com/seg2.ts');
    });

    test('detects live playlist without ENDLIST', () {
      const content = '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXTINF:6.0,
seg0.ts
''';
      final media =
          (parser.parse(content, playlistUrl: baseUrl) as MediaParseResult)
              .media;
      expect(media.isLive, isTrue);
    });

    test('parses AES-128 encryption with default IV', () {
      const content = '''
#EXTM3U
#EXT-X-KEY:METHOD=AES-128,URI="key.bin"
#EXTINF:10,
seg0.ts
#EXTINF:10,
seg1.ts
#EXT-X-ENDLIST
''';
      final media =
          (parser.parse(content, playlistUrl: baseUrl) as MediaParseResult)
              .media;

      expect(media.encrypted, isTrue);
      final key = media.segments[0].keyInfo!;
      expect(key.method, EncryptionMethod.aes128);
      expect(key.uri, 'https://cdn.example.com/video/key.bin');
      expect(key.ivHex, isNull);
      expect(media.segments[1].keyInfo, key);
    });

    test('parses explicit IV and key rotation', () {
      const content = '''
#EXTM3U
#EXT-X-KEY:METHOD=AES-128,URI="k1.bin",IV=0x00000000000000000000000000000001
#EXTINF:10,
seg0.ts
#EXT-X-KEY:METHOD=AES-256,URI="k2.bin"
#EXTINF:10,
seg1.ts
#EXT-X-KEY:METHOD=NONE
#EXTINF:10,
seg2.ts
#EXT-X-ENDLIST
''';
      final media =
          (parser.parse(content, playlistUrl: baseUrl) as MediaParseResult)
              .media;

      expect(media.segments[0].keyInfo!.method, EncryptionMethod.aes128);
      expect(media.segments[0].keyInfo!.ivHex,
          '00000000000000000000000000000001');
      expect(media.segments[1].keyInfo!.method, EncryptionMethod.aes256);
      expect(media.segments[1].keyInfo!.uri,
          'https://cdn.example.com/video/k2.bin');
      // METHOD=NONE clears encryption.
      expect(media.segments[2].keyInfo, isNull);
    });

    test('parses media sequence and discontinuity', () {
      const content = '''
#EXTM3U
#EXT-X-MEDIA-SEQUENCE:100
#EXTINF:10,
seg0.ts
#EXT-X-DISCONTINUITY
#EXTINF:10,
seg1.ts
#EXT-X-ENDLIST
''';
      final media =
          (parser.parse(content, playlistUrl: baseUrl) as MediaParseResult)
              .media;

      expect(media.mediaSequence, 100);
      expect(media.segments[0].seq, 100);
      expect(media.segments[1].seq, 101);
      expect(media.segments[0].discontinuity, isFalse);
      expect(media.segments[1].discontinuity, isTrue);
      expect(media.hasDiscontinuity, isTrue);
    });
  });

  group('master playlist parsing', () {
    test('parses variants sorted by bandwidth descending', () {
      const content = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360,CODECS="avc1.4d401e,mp4a.40.2"
low/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1280x720
mid/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=5000000,RESOLUTION=1920x1080
high/index.m3u8
''';
      final result = parser.parse(content, playlistUrl: baseUrl);
      expect(result, isA<MasterParseResult>());
      final master = (result as MasterParseResult).master;

      expect(master.variants.length, 3);
      // Sorted by bandwidth descending.
      expect(master.variants[0].bandwidth, 5000000);
      expect(master.variants[0].resolution, '1920x1080');
      expect(master.variants[0].url,
          'https://cdn.example.com/video/high/index.m3u8');
      expect(master.variants[2].bandwidth, 800000);
      expect(master.variants[2].codecs, 'avc1.4d401e,mp4a.40.2');
    });
  });

  group('error handling', () {
    test('rejects non-m3u8 content', () {
      expect(
        () => parser.parse('not a playlist', playlistUrl: baseUrl),
        throwsA(isA<M3u8ParseException>()),
      );
    });

    test('rejects empty media playlist', () {
      const content = '''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXT-X-ENDLIST
''';
      expect(
        () => parser.parse(content, playlistUrl: baseUrl),
        throwsA(isA<M3u8ParseException>()),
      );
    });
  });

  group('serialization round-trip', () {
    test('MediaPlaylist toJson/fromJson preserves data', () {
      const content = '''
#EXTM3U
#EXT-X-KEY:METHOD=AES-128,URI="key.bin"
#EXTINF:10,
seg0.ts
#EXT-X-ENDLIST
''';
      final media =
          (parser.parse(content, playlistUrl: baseUrl) as MediaParseResult)
              .media;

      final restored = MediaPlaylist.fromJson(media.toJson());
      expect(restored.segmentCount, media.segmentCount);
      expect(restored.segments[0].url, media.segments[0].url);
      expect(restored.segments[0].keyInfo, media.segments[0].keyInfo);
      expect(restored.totalDuration, media.totalDuration);
    });
  });
}
