/// Disk-full detection helpers for the download engine.
///
/// Pure Dart (no Flutter dependency). The engine cannot call the
/// `disk_usage` plugin directly, so free-space lookups are injected as a
/// [FreeSpaceQuery] callback by the app layer; this file only classifies
/// write failures and defines the exception used to pause a task.
library;

import 'dart:io';

/// Queries the free space (in bytes) available at [path].
///
/// Returns null when the platform cannot report it, in which case callers
/// skip proactive pre-flight checks and rely on write-failure detection.
typedef FreeSpaceQuery = Future<int?> Function(String path);

/// Thrown when a write fails because the target volume is full, or when a
/// pre-flight free-space check finds insufficient room. The engine catches
/// this to pause the task (rather than fail it) so the user can free space
/// and resume.
class DiskFullException implements Exception {
  const DiskFullException([this.message = 'No space left on device', this.path]);

  final String message;
  final String? path;

  @override
  String toString() => 'DiskFullException: $message';
}

/// OS error codes that mean "disk full".
///
/// - 28: POSIX `ENOSPC` (Linux, macOS).
/// - 39: POSIX `ENOSPC` on some BSD/Darwin libc variants.
/// - 112: Windows `ERROR_DISK_FULL`.
/// - 2250: Windows `ERROR_DISK_FULL` reported by some Win32 file APIs.
const Set<int> _diskFullErrorCodes = {28, 39, 112, 2250};

/// Lowercase substrings that indicate a full disk in an exception message,
/// used as a fallback when no structured OS error code is available.
const List<String> _diskFullMessages = [
  'no space left on device',
  'not enough space',
  'insufficient space',
  'disk full',
  'the disk is full',
  'errno = 28',
  'errno=28',
  'enospc',
];

/// Returns true when [error] represents a "disk full" condition.
///
/// Checks the structured [FileSystemException.osError] code first, then
/// falls back to matching well-known message substrings so wrapped or
/// stringified errors are still recognized.
bool isDiskFull(Object? error) {
  if (error == null) return false;

  if (error is FileSystemException) {
    final code = error.osError?.errorCode;
    if (code != null && _diskFullErrorCodes.contains(code)) return true;
  }

  final text = error.toString().toLowerCase();
  for (final needle in _diskFullMessages) {
    if (text.contains(needle)) return true;
  }
  return false;
}
