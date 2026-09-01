import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/m3u8/playlist.dart';

void main() {
  group('EncryptionMethod extension', () {
    test('keyBytes maps to key length', () {
      expect(EncryptionMethod.none.keyBytes, 0);
      expect(EncryptionMethod.aes128.keyBytes, 16);
      expect(EncryptionMethod.aes192.keyBytes, 24);
      expect(EncryptionMethod.aes256.keyBytes, 32);
    });

    test('label maps to HLS method string', () {
      expect(EncryptionMethod.none.label, 'NONE');
      expect(EncryptionMethod.aes128.label, 'AES-128');
      expect(EncryptionMethod.aes192.label, 'AES-192');
      expect(EncryptionMethod.aes256.label, 'AES-256');
    });
  });

  group('parseEncryptionMethod', () {
    test('maps known values and falls back to none', () {
      expect(parseEncryptionMethod('AES-128'), EncryptionMethod.aes128);
      expect(parseEncryptionMethod('AES-192'), EncryptionMethod.aes192);
      expect(parseEncryptionMethod('AES-256'), EncryptionMethod.aes256);
      expect(parseEncryptionMethod('NONE'), EncryptionMethod.none);
      expect(parseEncryptionMethod(null), EncryptionMethod.none);
      expect(parseEncryptionMethod('SAMPLE-AES'), EncryptionMethod.none);
    });
  });

  group('KeyInfo', () {
    test('encrypted reflects method', () {
      const none = KeyInfo(method: EncryptionMethod.none);
      const aes = KeyInfo(method: EncryptionMethod.aes128, uri: 'k.bin');
      expect(none.encrypted, isFalse);
      expect(aes.encrypted, isTrue);
    });

    test('json round trip preserves fields', () {
      const key = KeyInfo(
        method: EncryptionMethod.aes256,
        uri: 'https://cdn/key.bin',
        ivHex: '00112233445566778899aabbccddeeff',
      );
      final decoded = KeyInfo.fromJson(
        jsonDecode(jsonEncode(key.toJson())) as Map<String, dynamic>,
      );
      expect(decoded, key);
      expect(decoded.hashCode, key.hashCode);
    });

    test('fromJson falls back to none for unknown method', () {
      final decoded = KeyInfo.fromJson({'method': 'WEIRD'});
      expect(decoded.method, EncryptionMethod.none);
    });
  });

  group('MediaPlaylist serialization', () {
    test('json round trip preserves segments and metadata', () {
      const playlist = MediaPlaylist(
        segments: [
          Segment(
            seq: 0,
            url: 'https://cdn/seg0.ts',
            duration: 6.0,
            keyInfo: KeyInfo(
              method: EncryptionMethod.aes128,
              uri: 'key.bin',
            ),
          ),
          Segment(
            seq: 1,
            url: 'https://cdn/seg1.ts',
            duration: 4.5,
            discontinuity: true,
          ),
        ],
        totalDuration: 10.5,
        mediaSequence: 0,
        targetDuration: 6,
        version: 3,
      );

      final decoded = MediaPlaylist.fromJson(
        jsonDecode(jsonEncode(playlist.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.segmentCount, 2);
      expect(decoded.totalDuration, 10.5);
      expect(decoded.mediaSequence, 0);
      expect(decoded.isLive, isFalse);
      expect(decoded.targetDuration, 6);
      expect(decoded.version, 3);
      expect(decoded.encrypted, isTrue);
      expect(decoded.hasDiscontinuity, isTrue);
      expect(decoded.segments[0].keyInfo?.method, EncryptionMethod.aes128);
      expect(decoded.segments[1].discontinuity, isTrue);
      expect(decoded.segments[1].keyInfo, isNull);
    });

    test('fromJson defaults optional fields', () {
      final decoded = MediaPlaylist.fromJson({
        'segments': <dynamic>[],
        'totalDuration': 0,
        'mediaSequence': 5,
      });
      expect(decoded.isLive, isFalse);
      expect(decoded.targetDuration, isNull);
      expect(decoded.version, isNull);
      expect(decoded.encrypted, isFalse);
      expect(decoded.hasDiscontinuity, isFalse);
    });
  });

  group('Variant', () {
    test('displayName prefers explicit name', () {
      const v = Variant(url: 'u', name: '1080p');
      expect(v.displayName, '1080p');
    });

    test('displayName composes resolution and bandwidth', () {
      const v = Variant(url: 'u', resolution: '1920x1080', bandwidth: 4500000);
      expect(v.displayName, '1920x1080 · 4500 kbps');
    });

    test('displayName falls back to url', () {
      const v = Variant(url: 'https://cdn/v.m3u8');
      expect(v.displayName, 'https://cdn/v.m3u8');
    });

    test('json round trip preserves fields', () {
      const v = Variant(
        url: 'https://cdn/v.m3u8',
        bandwidth: 1200000,
        resolution: '1280x720',
        codecs: 'avc1.4d401f',
        name: '720p',
      );
      final decoded = Variant.fromJson(
        jsonDecode(jsonEncode(v.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.url, v.url);
      expect(decoded.bandwidth, v.bandwidth);
      expect(decoded.resolution, v.resolution);
      expect(decoded.codecs, v.codecs);
      expect(decoded.name, v.name);
    });
  });

  group('MasterPlaylist serialization', () {
    test('json round trip preserves variants', () {
      const master = MasterPlaylist(variants: [
        Variant(url: 'a.m3u8', bandwidth: 3000000),
        Variant(url: 'b.m3u8', bandwidth: 1000000),
      ]);
      final decoded = MasterPlaylist.fromJson(
        jsonDecode(jsonEncode(master.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.variants.length, 2);
      expect(decoded.variants[0].url, 'a.m3u8');
      expect(decoded.variants[1].bandwidth, 1000000);
    });
  });
}
