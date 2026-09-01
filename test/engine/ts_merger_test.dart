import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/merge/ts_merger.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ts_merger_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('merges segments in order byte-for-byte', () async {
    final segA = File('${tempDir.path}/a.ts')
      ..writeAsBytesSync(List.generate(100, (i) => i));
    final segB = File('${tempDir.path}/b.ts')
      ..writeAsBytesSync(List.generate(50, (i) => 200 - i));
    final segC = File('${tempDir.path}/c.ts')
      ..writeAsBytesSync(List.filled(30, 42));

    final output = File('${tempDir.path}/out.ts');
    const merger = TsMerger();

    final progress = <double>[];
    await merger.merge(
      [segA, segB, segC],
      outputFile: output,
      onProgress: (written, total) => progress.add(written / total),
    );

    final expected = BytesBuilder(copy: false)
      ..add(segA.readAsBytesSync())
      ..add(segB.readAsBytesSync())
      ..add(segC.readAsBytesSync());

    expect(output.readAsBytesSync(), expected.takeBytes());
    // Progress is monotonically increasing and ends at 1.0.
    expect(progress.last, closeTo(1.0, 0.0001));
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
    }
  });

  test('throws when a segment file is missing', () async {
    final segA = File('${tempDir.path}/a.ts')..writeAsBytesSync([1, 2, 3]);
    final missing = File('${tempDir.path}/missing.ts');
    final output = File('${tempDir.path}/out.ts');

    const merger = TsMerger();
    expect(
      () => merger.merge([segA, missing], outputFile: output),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('handles empty segment list', () async {
    final output = File('${tempDir.path}/out.ts');
    const merger = TsMerger();
    await merger.merge([], outputFile: output);
    expect(output.readAsBytesSync(), isEmpty);
  });
}
