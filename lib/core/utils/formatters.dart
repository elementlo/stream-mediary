/// Formatting helpers for sizes, speeds and durations.
library;

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 100 || unit == 0 ? 0 : 1)} '
      '${units[unit]}';
}

String formatSpeed(double bytesPerSecond) =>
    formatBytes(bytesPerSecond.round());

String formatDuration(double seconds) {
  if (seconds <= 0 || !seconds.isFinite) return '--:--';
  final total = seconds.round();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

String formatEta(double bytesPerSecond, int remainingBytes) {
  if (bytesPerSecond <= 0) return '--';
  final seconds = remainingBytes / bytesPerSecond;
  return formatDuration(seconds);
}

/// Compact absolute timestamp for history rows, e.g. `09-17 16:45`.
///
/// Omits the year for the current year and seconds entirely — history rows are
/// scanned, not read, and a full ISO timestamp is pure noise at 12px.
String formatTimestamp(int millisecondsSinceEpoch) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  final now = DateTime.now();
  final mm = dt.month.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mi = dt.minute.toString().padLeft(2, '0');
  final stamp = '$mm-$dd $hh:$mi';
  return dt.year == now.year ? stamp : '${dt.year}-$stamp';
}
