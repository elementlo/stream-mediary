import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/features/update/update_service.dart';

void main() {
  group('isNewerVersion', () {
    test('detects newer, equal and older releases', () {
      expect(isNewerVersion('v0.0.9', '0.0.8'), isTrue);
      expect(isNewerVersion('v0.1.0', '0.0.9'), isTrue);
      expect(isNewerVersion('v1.0.0', '0.9.9'), isTrue);
      expect(isNewerVersion('v0.0.8', '0.0.8'), isFalse);
      expect(isNewerVersion('v0.0.7', '0.0.8'), isFalse);
    });

    test('ignores build and prerelease suffixes', () {
      expect(isNewerVersion('v0.0.10+10', '0.0.9+9'), isTrue);
      expect(isNewerVersion('v0.0.9', '0.0.9+9'), isFalse);
    });

    test('compares differing segment counts', () {
      expect(isNewerVersion('v0.0.9.1', '0.0.9'), isTrue);
      expect(isNewerVersion('v0.0.9', '0.0.9.1'), isFalse);
    });
  });

  group('pickAssetName', () {
    const names = [
      'Mediary-android-arm64-v8a.apk',
      'Mediary-android-armeabi-v7a.apk',
      'Mediary-ios-unsigned.app.zip',
      'Mediary-macos-arm64.zip',
      'Mediary-windows-x64.zip',
      'SHA256SUMS.txt',
    ];

    test('selects the right Android ABI', () {
      expect(
        pickAssetName(names, platform: 'android', arch: 'arm64'),
        'Mediary-android-arm64-v8a.apk',
      );
      expect(
        pickAssetName(names, platform: 'android', arch: 'armv7'),
        'Mediary-android-armeabi-v7a.apk',
      );
    });

    test('selects macOS and Windows packages', () {
      expect(
        pickAssetName(names, platform: 'macos', arch: 'arm64'),
        'Mediary-macos-arm64.zip',
      );
      expect(
        pickAssetName(names, platform: 'windows', arch: 'x64'),
        'Mediary-windows-x64.zip',
      );
    });

    test('never selects iOS or checksum files', () {
      expect(pickAssetName(names, platform: 'ios', arch: ''), isNull);
      // Non-arm64 Android (e.g. an x86_64 emulator) falls back to armv7.
      expect(
        pickAssetName(names, platform: 'android', arch: 'x64'),
        'Mediary-android-armeabi-v7a.apk',
      );
      expect(pickAssetName(['SHA256SUMS.txt'], platform: 'windows', arch: 'x64'),
          isNull);
    });
  });

  group('parseDigest', () {
    test('extracts a valid sha256 hex', () {
      final hex = 'a' * 64;
      expect(parseDigest('sha256:$hex'), hex);
    });

    test('rejects malformed or non-sha256 digests', () {
      expect(parseDigest(null), isNull);
      expect(parseDigest('md5:${'a' * 32}'), isNull);
      expect(parseDigest('sha256:tooshort'), isNull);
      expect(parseDigest('nocolon'), isNull);
    });
  });
}
