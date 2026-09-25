/// Extracts HLS bytes hidden in a PNG `roUd` chunk.
library;

import 'dart:io';
import 'dart:typed_data';

const _pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];

bool isPng(List<int> bytes) {
  if (bytes.length < _pngSignature.length) return false;
  for (var i = 0; i < _pngSignature.length; i++) {
    if (bytes[i] != _pngSignature[i]) return false;
  }
  return true;
}

/// Returns the original bytes for ordinary HLS resources.
Uint8List unwrapRoud(List<int> bytes) {
  if (!isPng(bytes)) return Uint8List.fromList(bytes);
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final view = ByteData.sublistView(data);
  var offset = _pngSignature.length;
  while (offset + 12 <= data.length) {
    final length = view.getUint32(offset);
    final end = offset + 12 + length;
    if (end > data.length) throw const FormatException('Truncated PNG chunk');
    if (data[offset + 4] == 0x72 &&
        data[offset + 5] == 0x6f &&
        data[offset + 6] == 0x55 &&
        data[offset + 7] == 0x64) {
      if (length == 0) throw const FormatException('Empty roUd chunk');
      final flags = data[offset + 8];
      final payload = data.sublist(offset + 9, offset + 8 + length);
      if ((flags & 1) == 0) return Uint8List.fromList(payload);
      try {
        return Uint8List.fromList(zlib.decode(payload));
      } on Exception {
        return Uint8List.fromList(ZLibDecoder(raw: true).convert(payload));
      }
    }
    offset = end;
  }
  throw const FormatException('PNG has no roUd chunk');
}
