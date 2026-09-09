import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:stream_mediary/engine/merge/folder_merger.dart';

void main() {
  group('naturalCompare', () {
    test('orders numeric runs by value, not lexicographically', () {
      final names = ['10', '2', '1'];
      names.sort(FolderMerger.naturalCompare);
      expect(names, ['1', '2', '10']);
    });

    test('handles zero-padded names', () {
      final names = ['000010', '000002', '000001'];
      names.sort(FolderMerger.naturalCompare);
      expect(names, ['000001', '000002', '000010']);
    });

    test('handles prefixed names', () {
      final names = ['seg10', 'seg2', 'seg1'];
      names.sort(FolderMerger.naturalCompare);
      expect(names, ['seg1', 'seg2', 'seg10']);
    });

    test('mixed alphanumeric', () {
      final names = ['a1b10', 'a1b2', 'a2b1'];
      names.sort(FolderMerger.naturalCompare);
      expect(names, ['a1b2', 'a1b10', 'a2b1']);
    });

    test('same value with different leading zeros is deterministic', () {
      // Fewer leading zeros sorts first.
      expect(FolderMerger.naturalCompare('1', '01'), lessThan(0));
      expect(FolderMerger.naturalCompare('01', '1'), greaterThan(0));
    });

    test('falls back to lexicographic without digits', () {
      final names = ['b', 'a', 'c'];
      names.sort(FolderMerger.naturalCompare);
      expect(names, ['a', 'b', 'c']);
    });

    test('is case-insensitive for letters', () {
      expect(FolderMerger.naturalCompare('A2', 'b10'), lessThan(0));
      expect(FolderMerger.naturalCompare('Seg2', 'seg10'), lessThan(0));
    });

    test('digits sort before letters', () {
      expect(FolderMerger.naturalCompare('1abc', 'abc1'), lessThan(0));
    });

    test('prefix sorts before longer name', () {
      expect(FolderMerger.naturalCompare('seg1', 'seg1x'), lessThan(0));
    });

    test('very long digit runs do not overflow', () {
      final big = '9' * 30;
      final bigger = '1${'0' * 30}';
      expect(FolderMerger.naturalCompare(big, bigger), lessThan(0));
    });
  });

  group('scan', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('folder_merger_scan');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('finds top-level .ts files in natural order', () async {
      for (final n in ['10.ts', '2.ts', '1.ts']) {
        File(p.join(tempDir.path, n)).writeAsBytesSync([1]);
      }
      final result = await const FolderMerger().scan(tempDir);
      expect(result.error, isNull);
      expect(
        result.segments.map((f) => p.basename(f.path)).toList(),
        ['1.ts', '2.ts', '10.ts'],
      );
    });

    test('recognizes uppercase .TS extension', () async {
      File(p.join(tempDir.path, 'a.TS')).writeAsBytesSync([1]);
      final result = await const FolderMerger().scan(tempDir);
      expect(result.segments, hasLength(1));
    });

    test('ignores subdirectories and non-ts files', () async {
      File(p.join(tempDir.path, '1.ts')).writeAsBytesSync([1]);
      File(p.join(tempDir.path, 'notes.txt')).writeAsBytesSync([1]);
      final sub = Directory(p.join(tempDir.path, 'sub'))..createSync();
      File(p.join(sub.path, '2.ts')).writeAsBytesSync([1]);

      final result = await const FolderMerger().scan(tempDir);
      expect(result.segments, hasLength(1));
      expect(p.basename(result.segments.first.path), '1.ts');
    });

    test('excludes a previous merge output named after the folder',
        () async {
      final folder = Directory(p.join(tempDir.path, 'video'))..createSync();
      File(p.join(folder.path, '1.ts')).writeAsBytesSync([1]);
      File(p.join(folder.path, '2.ts')).writeAsBytesSync([2, 3]);
      // Previous output: named after the folder and byte-exactly the sum of
      // the segments (1 + 2 = 3 bytes).
      File(p.join(folder.path, 'video.ts')).writeAsBytesSync([1, 2, 3]);

      final result = await const FolderMerger().scan(folder);
      expect(
        result.segments.map((f) => p.basename(f.path)).toList(),
        ['1.ts', '2.ts'],
      );
      expect(result.totalBytes, 3);
    });

    test('keeps a genuine segment named after the folder when sizes differ',
        () async {
      final folder = Directory(p.join(tempDir.path, 'clip'))..createSync();
      File(p.join(folder.path, '1.ts')).writeAsBytesSync([1]);
      // Same name as the folder but NOT the size of the other segments,
      // so it is a genuine segment, not a previous output.
      File(p.join(folder.path, 'clip.ts')).writeAsBytesSync([7, 7, 7, 7]);

      final result = await const FolderMerger().scan(folder);
      expect(
        result.segments.map((f) => p.basename(f.path)).toList(),
        ['1.ts', 'clip.ts'],
      );
    });

    test('reports folderUnreadable for a missing directory', () async {
      final missing = Directory(p.join(tempDir.path, 'nope'));
      final result = await const FolderMerger().scan(missing);
      expect(result.error, FolderMergeError.folderUnreadable);
      expect(result.isEmpty, isTrue);
    });

    test('empty directory yields isEmpty without error', () async {
      final result = await const FolderMerger().scan(tempDir);
      expect(result.error, isNull);
      expect(result.isEmpty, isTrue);
    });

    test('totalBytes sums segment sizes', () async {
      File(p.join(tempDir.path, '1.ts')).writeAsBytesSync(List.filled(10, 0));
      File(p.join(tempDir.path, '2.ts')).writeAsBytesSync(List.filled(20, 0));
      final result = await const FolderMerger().scan(tempDir);
      expect(result.totalBytes, 30);
    });
  });

  group('mergeFolder', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('folder_merger_merge');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('concatenates out-of-order segments in natural order', () async {
      final folder = Directory(p.join(tempDir.path, 'show'))..createSync();
      final s1 = File(p.join(folder.path, '1.ts'))
        ..writeAsBytesSync(List.generate(100, (i) => i));
      final s2 = File(p.join(folder.path, '2.ts'))
        ..writeAsBytesSync(List.generate(50, (i) => 200 - i));
      final s10 = File(p.join(folder.path, '10.ts'))
        ..writeAsBytesSync(List.filled(30, 42));

      final progress = <double>[];
      final result = await const FolderMerger().mergeFolder(
        folder,
        preferMp4: false,
        onProgress: (w, t) => progress.add(w / t),
      );

      expect(result.success, isTrue);
      expect(result.segmentCount, 3);
      expect(result.totalBytes, 180);
      expect(result.downgradedToTs, isFalse);
      expect(p.basename(result.outputFile!.path), 'show.ts');

      final expected = BytesBuilder(copy: false)
        ..add(s1.readAsBytesSync())
        ..add(s2.readAsBytesSync())
        ..add(s10.readAsBytesSync());
      expect(result.outputFile!.readAsBytesSync(), expected.takeBytes());

      expect(progress.last, closeTo(1.0, 0.0001));
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
      }
    });

    test('empty folder reports noTsFiles and writes nothing', () async {
      final folder = Directory(p.join(tempDir.path, 'empty'))..createSync();
      final result =
          await const FolderMerger().mergeFolder(folder, preferMp4: false);
      expect(result.error, FolderMergeError.noTsFiles);
      expect(result.success, isFalse);
      expect(folder.listSync(), isEmpty);
    });

    test('missing folder reports folderUnreadable', () async {
      final folder = Directory(p.join(tempDir.path, 'gone'));
      final result =
          await const FolderMerger().mergeFolder(folder, preferMp4: false);
      expect(result.error, FolderMergeError.folderUnreadable);
    });

    test('output name collision appends _merged', () async {
      // Folder named "1" containing a segment "1.ts": the output must not
      // overwrite the segment.
      final folder = Directory(p.join(tempDir.path, '1'))..createSync();
      File(p.join(folder.path, '1.ts')).writeAsBytesSync([1, 2, 3]);

      final result =
          await const FolderMerger().mergeFolder(folder, preferMp4: false);
      expect(result.success, isTrue);
      expect(p.basename(result.outputFile!.path), '1_merged.ts');
      expect(result.outputFile!.readAsBytesSync(), [1, 2, 3]);
      // The original segment is untouched.
      expect(File(p.join(folder.path, '1.ts')).readAsBytesSync(), [1, 2, 3]);
    });

    test('preferMp4 succeeds with mp4 or documented ts downgrade', () async {
      final folder = Directory(p.join(tempDir.path, 'mp4test'))..createSync();
      File(p.join(folder.path, '1.ts')).writeAsBytesSync(List.filled(10, 7));

      final phases = <FolderMergePhase>[];
      final result = await const FolderMerger().mergeFolder(
        folder,
        preferMp4: true,
        onPhaseChanged: phases.add,
      );

      expect(result.success, isTrue);
      expect(phases.first, FolderMergePhase.concatenating);
      final out = result.outputFile!.path;
      if (result.downgradedToTs) {
        // No ffmpeg (or mobile): the .ts is kept.
        expect(out, endsWith('.ts'));
      } else {
        expect(out, endsWith('.mp4'));
        expect(phases, contains(FolderMergePhase.remuxing));
        // Intermediate .ts removed after a successful remux.
        expect(File(p.join(folder.path, 'mp4test.ts')).existsSync(), isFalse);
      }
    });
  });
}
