/// Streaming AES-CBC decryption for HLS segments.
///
/// Supports AES-128/192/256 in CBC mode with PKCS7 padding removal on the
/// final block of each segment. Designed for constant memory usage: data is
/// processed in 16-byte blocks and only the trailing block is buffered until
/// end-of-stream, when padding is stripped.
library;

import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Thrown when decryption input is malformed.
class AesDecryptException implements Exception {
  const AesDecryptException(this.message);
  final String message;

  @override
  String toString() => 'AesDecryptException: $message';
}

/// Parses a hex string (optionally 0x-prefixed) into bytes.
Uint8List hexToBytes(String hex) {
  var text = hex.trim();
  if (text.toLowerCase().startsWith('0x')) {
    text = text.substring(2);
  }
  if (text.length % 2 != 0) {
    throw AesDecryptException('Hex string has odd length: $hex');
  }
  final out = Uint8List(text.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    final byte = int.tryParse(text.substring(i * 2, i * 2 + 2), radix: 16);
    if (byte == null) {
      throw AesDecryptException('Invalid hex character in: $hex');
    }
    out[i] = byte;
  }
  return out;
}

/// Builds the default IV for a segment: the media sequence number encoded as
/// a 16-byte big-endian value.
Uint8List defaultIvForSequence(int sequence) {
  final iv = Uint8List(16);
  final view = ByteData.view(iv.buffer);
  view.setUint64(8, sequence, Endian.big);
  return iv;
}

/// A streaming AES-CBC decryptor.
///
/// Feed arbitrary-sized chunks via [process]; complete 16-byte blocks are
/// emitted immediately. Call [finalize] at end-of-stream to strip PKCS7
/// padding from the last buffered block.
class AesCbcDecryptor {
  AesCbcDecryptor({
    required Uint8List key,
    required Uint8List iv,
  }) {
    if (key.length != 16 && key.length != 24 && key.length != 32) {
      throw AesDecryptException('Invalid AES key length: ${key.length}');
    }
    if (iv.length != 16) {
      throw AesDecryptException('Invalid IV length: ${iv.length}');
    }
    _cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), iv));
  }

  static const int _blockSize = 16;

  late final BlockCipher _cipher;

  final BytesBuilder _pending = BytesBuilder(copy: false);
  bool _finalized = false;

  /// Processes [chunk], returning zero or more complete decrypted blocks.
  ///
  /// The trailing 16 bytes (or partial block) are always kept buffered so
  /// that [finalize] can strip PKCS7 padding from the true final block.
  Uint8List process(Uint8List chunk) {
    if (_finalized) {
      throw const AesDecryptException('process() called after finalize()');
    }
    _pending.add(chunk);
    final buffered = _pending.takeBytes();

    // Keep at least one block (16 bytes) buffered for finalize.
    final keep = buffered.length % _blockSize == 0
        ? _blockSize
        : buffered.length % _blockSize;
    final emitLen = buffered.length - keep;
    if (emitLen <= 0) {
      _pending.add(buffered);
      return Uint8List(0);
    }

    final tail = Uint8List.sublistView(buffered, emitLen);
    _pending.add(tail);

    return _decryptBlocks(Uint8List.sublistView(buffered, 0, emitLen));
  }

  /// Finalizes decryption, stripping PKCS7 padding from the final block.
  Uint8List finalize() {
    if (_finalized) {
      throw const AesDecryptException('finalize() called twice');
    }
    _finalized = true;
    final tail = _pending.takeBytes();
    if (tail.isEmpty) {
      return Uint8List(0);
    }
    if (tail.length % _blockSize != 0) {
      throw AesDecryptException(
          'Ciphertext length ${tail.length} is not a multiple of block size');
    }

    final decrypted = _decryptBlocks(tail);
    return _stripPkcs7(decrypted);
  }

  Uint8List _decryptBlocks(Uint8List input) {
    final out = Uint8List(input.length);
    for (var offset = 0; offset < input.length; offset += _blockSize) {
      _cipher.processBlock(input, offset, out, offset);
    }
    return out;
  }

  Uint8List _stripPkcs7(Uint8List data) {
    if (data.isEmpty) return data;
    final pad = data[data.length - 1];
    if (pad < 1 || pad > _blockSize || pad > data.length) {
      throw AesDecryptException('Invalid PKCS7 padding value: $pad');
    }
    for (var i = data.length - pad; i < data.length; i++) {
      if (data[i] != pad) {
        throw AesDecryptException('Corrupt PKCS7 padding');
      }
    }
    return Uint8List.sublistView(data, 0, data.length - pad);
  }
}

/// Decrypts an entire segment provided as a byte stream.
///
/// Returns a stream of decrypted bytes with PKCS7 padding removed.
Stream<Uint8List> decryptSegmentStream(
  Stream<List<int>> input, {
  required Uint8List key,
  required Uint8List iv,
}) async* {
  final decryptor = AesCbcDecryptor(key: key, iv: iv);
  await for (final chunk in input) {
    final out = decryptor.process(Uint8List.fromList(chunk));
    if (out.isNotEmpty) yield out;
  }
  final tail = decryptor.finalize();
  if (tail.isNotEmpty) yield tail;
}
