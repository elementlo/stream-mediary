import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/disk_space.dart';

void main() {
  group('isDiskFull', () {
    test('detects POSIX ENOSPC (errno 28) via osError code', () {
      final e = FileSystemException(
        'write failed',
        '/tmp/x.ts',
        const OSError('No space left on device', 28),
      );
      expect(isDiskFull(e), isTrue);
    });

    test('detects Windows ERROR_DISK_FULL (112) via osError code', () {
      final e = FileSystemException(
        'write failed',
        r'C:\out.ts',
        const OSError('The disk is full', 112),
      );
      expect(isDiskFull(e), isTrue);
    });

    test('detects disk-full from message text without an osError', () {
      expect(isDiskFull(Exception('No space left on device')), isTrue);
      expect(isDiskFull(Exception('errno = 28')), isTrue);
      expect(isDiskFull(Exception('Disk full while writing')), isTrue);
    });

    test('is case-insensitive on message matching', () {
      expect(isDiskFull(Exception('NO SPACE LEFT ON DEVICE')), isTrue);
    });

    test('returns false for unrelated errors', () {
      expect(isDiskFull(null), isFalse);
      expect(isDiskFull(Exception('connection refused')), isFalse);
      expect(
        isDiskFull(
          FileSystemException('gone', '/x', const OSError('not found', 2)),
        ),
        isFalse,
      );
    });
  });

  group('DiskFullException', () {
    test('carries message and path', () {
      const e = DiskFullException('no room', '/data');
      expect(e.message, 'no room');
      expect(e.path, '/data');
      expect(e.toString(), contains('no room'));
    });

    test('has a default message', () {
      const e = DiskFullException();
      expect(e.message, isNotEmpty);
    });
  });
}
