import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/core/utils/dio_proxy.dart';

void main() {
  group('normalizeProxy', () {
    test('returns null for a missing or blank host (direct connection)', () {
      expect(normalizeProxy(null, null), isNull);
      expect(normalizeProxy('', 8080), isNull);
      expect(normalizeProxy('   ', 7890), isNull);
    });

    test('combines host and port', () {
      expect(normalizeProxy('127.0.0.1', 7890), '127.0.0.1:7890');
      expect(normalizeProxy('proxy.local', 1080), 'proxy.local:1080');
    });

    test('trims surrounding whitespace from the host', () {
      expect(normalizeProxy('  127.0.0.1  ', 7890), '127.0.0.1:7890');
    });

    test('defaults the port to 8080 when omitted', () {
      expect(normalizeProxy('127.0.0.1', null), '127.0.0.1:8080');
    });
  });
}
