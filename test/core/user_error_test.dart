import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/core/l10n/app_localizations_zh.dart';
import 'package:stream_mediary/core/utils/user_error.dart';
import 'package:stream_mediary/engine/m3u8/m3u8_parser.dart';

void main() {
  final l10n = AppLocalizationsZh();

  test('HTTP failure hides signed URL and technical details', () {
    final options = RequestOptions(
      path: 'https://example.test/video?sig=secret',
    );
    final error = DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 403),
    );
    final message = userErrorMessage(error, l10n);
    expect(message, contains('访问被拒绝'));
    expect(message, isNot(contains('secret')));
    expect(message, isNot(contains('DioException')));
  });

  test('playlist parser failure is understandable', () {
    final message = userErrorMessage(
      const M3u8ParseException('Not an m3u8 playlist (missing #EXTM3U)'),
      l10n,
    );
    expect(message, contains('HLS 视频'));
    expect(message, isNot(contains('EXTM3U')));
  });

  test('unknown exception does not leak implementation details', () {
    final message = userErrorMessage(StateError('internal path /secret'), l10n);
    expect(message, contains('稍后重试'));
    expect(message, isNot(contains('/secret')));
  });
}
