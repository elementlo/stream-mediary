import 'dart:io';

/// Serves a synthetic m3u8 playlist and its segments over localhost HTTP.
///
/// Shared across engine test files so each suite can stand up an isolated
/// server without duplicating the routing logic.
class FakeHlsServer {
  HttpServer? _server;
  late String baseUrl;

  /// segment index -> bytes
  final Map<int, List<int>> segments = {};
  final Map<int, int> segmentRequests = {};
  String playlist = '';
  List<int>? rangeMedia;
  final List<String> rangesRequested = [];

  /// When set, every segment request returns this status instead of 200.
  int? segmentOverrideStatus;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${_server!.port}';
    _server!.listen((request) {
      final path = request.uri.path;
      if (path == '/index.m3u8') {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType(
            'application',
            'vnd.apple.mpegurl',
          )
          ..write(playlist);
      } else if (path == '/movie.mp4' && rangeMedia != null) {
        final value = request.headers.value(HttpHeaders.rangeHeader);
        if (value == null) {
          request.response.statusCode = 400;
        } else {
          rangesRequested.add(value);
          final match = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(value)!;
          final start = int.parse(match.group(1)!);
          final end = int.parse(match.group(2)!);
          request.response
            ..statusCode = 206
            ..headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes $start-$end/${rangeMedia!.length}',
            )
            ..add(rangeMedia!.sublist(start, end + 1));
        }
      } else if (path.startsWith('/seg')) {
        final idx = int.parse(
          path.substring('/seg'.length).replaceAll('.ts', ''),
        );
        segmentRequests[idx] = (segmentRequests[idx] ?? 0) + 1;
        final data = segments[idx];
        if (segmentOverrideStatus != null) {
          request.response.statusCode = segmentOverrideStatus!;
        } else if (data == null) {
          request.response.statusCode = 404;
        } else if (request.method == 'HEAD') {
          // estimateMediaBytes probes sizes via HEAD; report length, no body.
          request.response
            ..statusCode = 200
            ..contentLength = data.length;
        } else {
          request.response
            ..statusCode = 200
            ..add(data);
        }
      } else {
        request.response.statusCode = 404;
      }
      request.response.close();
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }
}
