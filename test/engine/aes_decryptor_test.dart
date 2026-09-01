import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:stream_mediary/engine/crypto/aes_decryptor.dart';

/// Encrypts [plain] with AES-CBC + PKCS7 for test fixtures.
Uint8List _encrypt(Uint8List plain, Uint8List key, Uint8List iv) {
  final cipher = PaddedBlockCipher('AES/CBC/PKCS7')
    ..init(
      true,
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );
  return cipher.process(plain);
}

void main() {
  group('hexToBytes', () {
    test('parses plain and 0x-prefixed hex', () {
      expect(hexToBytes('00ff10'), Uint8List.fromList([0, 255, 16]));
      expect(hexToBytes('0x00ff10'), Uint8List.fromList([0, 255, 16]));
    });

    test('rejects odd-length and invalid hex', () {
      expect(() => hexToBytes('abc'), throwsA(isA<AesDecryptException>()));
      expect(() => hexToBytes('zz'), throwsA(isA<AesDecryptException>()));
    });
  });

  group('defaultIvForSequence', () {
    test('encodes sequence as 16-byte big-endian', () {
      final iv = defaultIvForSequence(1);
      expect(iv.length, 16);
      expect(iv[15], 1);
      expect(iv[0], 0);

      final iv256 = defaultIvForSequence(256);
      expect(iv256[14], 1);
      expect(iv256[15], 0);
    });
  });

  group('AES-CBC decryption', () {
    final key128 = Uint8List.fromList(List.generate(16, (i) => i));
    final key192 = Uint8List.fromList(List.generate(24, (i) => i));
    final key256 = Uint8List.fromList(List.generate(32, (i) => i));
    final iv = Uint8List.fromList(List.generate(16, (i) => 100 - i));

    test('round-trips AES-128 with chunked streaming', () async {
      final plain = Uint8List.fromList(
          utf8.encode('Hello HLS segment data! ' * 40));
      final cipher = _encrypt(plain, key128, iv);

      final chunks = <Uint8List>[];
      // Feed in awkward chunk sizes to exercise buffering.
      for (var i = 0; i < cipher.length; i += 7) {
        chunks.add(Uint8List.fromList(
            cipher.sublist(i, (i + 7).clamp(0, cipher.length))));
      }

      final decrypted = await _collect(
          decryptSegmentStream(Stream.fromIterable(chunks),
              key: key128, iv: iv));
      expect(decrypted, plain);
    });

    test('round-trips AES-192', () async {
      final plain = Uint8List.fromList(List.generate(1000, (i) => i % 251));
      final cipher = _encrypt(plain, key192, iv);

      final decrypted = await _collect(decryptSegmentStream(
          Stream.value(cipher),
          key: key192,
          iv: iv));
      expect(decrypted, plain);
    });

    test('round-trips AES-256', () async {
      final plain = Uint8List.fromList(List.generate(4096, (i) => i % 199));
      final cipher = _encrypt(plain, key256, iv);

      final decrypted = await _collect(decryptSegmentStream(
          Stream.value(cipher),
          key: key256,
          iv: iv));
      expect(decrypted, plain);
    });

    test('handles single-block plaintext', () async {
      final plain = Uint8List.fromList(List.filled(16, 7));
      final cipher = _encrypt(plain, key128, iv);

      final decrypted = await _collect(decryptSegmentStream(
          Stream.value(cipher),
          key: key128,
          iv: iv));
      expect(decrypted, plain);
    });

    test('rejects invalid key length', () {
      expect(
        () => AesCbcDecryptor(key: Uint8List(15), iv: iv),
        throwsA(isA<AesDecryptException>()),
      );
    });

    test('rejects invalid IV length', () {
      expect(
        () => AesCbcDecryptor(key: key128, iv: Uint8List(8)),
        throwsA(isA<AesDecryptException>()),
      );
    });

    test('finalize rejects non-block-aligned tail', () {
      final decryptor = AesCbcDecryptor(key: key128, iv: iv);
      decryptor.process(Uint8List.fromList(List.filled(10, 1)));
      expect(() => decryptor.finalize(),
          throwsA(isA<AesDecryptException>()));
    });
  });
}

Future<Uint8List> _collect(Stream<Uint8List> stream) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}
