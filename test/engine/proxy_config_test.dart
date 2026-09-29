import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/download_engine.dart';
import 'package:stream_mediary/engine/engine_config.dart';
import 'package:stream_mediary/engine/m3u8/playlist.dart';

import 'in_memory_task_store.dart';

/// A minimal forwarding HTTP proxy that counts every request it relays.
///
/// A real proxy receives the absolute-form request target
/// (`GET http://host/path HTTP/1.1`). We open a socket to the origin, replay
/// the request and stream the response back, incrementing [relayed] per hop.
class _CountingProxy {
  _CountingProxy();

  HttpServer? _server;
  late String host;
  late int port;

  /// Number of requests forwarded through this proxy.
  int relayed = 0;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    host = '127.0.0.1';
    port = _server!.port;
    _server!.listen(_handle);
  }

  Future<void> _handle(HttpRequest request) async {
    relayed++;
    // Absolute-form URI as sent to a proxy.
    final target = request.uri;
    try {
      final client = HttpClient();
      final upstream = await client.openUrl(request.method, target);
      request.headers.forEach((name, values) {
        // Hop-by-hop header; forwarding it confuses the origin.
        if (name.toLowerCase() == 'proxy-connection') return;
        upstream.headers.set(name, values);
      });
      await upstream.addStream(request);
      final response = await upstream.close();
      request.response.statusCode = response.statusCode;
      response.headers.forEach((name, values) {
        request.response.headers.set(name, values);
      });
      await response.pipe(request.response);
      client.close();
    } catch (_) {
      request.response.statusCode = 502;
      await request.response.close();
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }
}

/// A tiny origin server: one playlist and one segment, counting direct hits.
class _OriginServer {
  HttpServer? _server;
  late String baseUrl;
  int playlistHits = 0;
  int segmentHits = 0;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${_server!.port}';
    _server!.listen((request) {
      final path = request.uri.path;
      if (path == '/index.m3u8') {
        playlistHits++;
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType('application', 'vnd.apple.mpegurl')
          ..write('#EXTM3U\n#EXT-X-TARGETDURATION:2\n'
              '#EXTINF:2.0,\nseg0.ts\n#EXT-X-ENDLIST\n');
      } else if (path == '/seg0.ts') {
        segmentHits++;
        request.response
          ..statusCode = 200
          ..add(List<int>.filled(32, 7));
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

void main() {
  late _CountingProxy proxy;
  late _OriginServer origin;
  late Directory tempDir;

  setUp(() async {
    proxy = _CountingProxy();
    origin = _OriginServer();
    await proxy.start();
    await origin.start();
    tempDir = await Directory.systemTemp.createTemp('proxy_cfg');
  });

  tearDown(() async {
    await proxy.stop();
    await origin.stop();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  DownloadEngine buildEngine(EngineConfig config) => DownloadEngine(
        store: InMemoryTaskStore(),
        config: config,
        defaultSaveDir: tempDir.path,
      );

  test('playlist + segment traffic goes through the proxy when configured',
      () async {
    final engine = buildEngine(
      EngineConfig(preferMp4: false, proxyHost: proxy.host, proxyPort: proxy.port),
    );

    final parsed = await engine.parseForPreview('${origin.baseUrl}/index.m3u8');
    expect(parsed, isA<MediaParseResult>());
    final media = (parsed as MediaParseResult).media;

    await engine.startTask(
      id: 'task-proxy',
      request: DownloadRequest(url: '${origin.baseUrl}/index.m3u8'),
      playlist: media,
    );
    // Wait for the single segment to land.
    await _waitFor(() => origin.segmentHits >= 1);

    // Both the playlist fetch and the segment fetch were relayed by the proxy.
    expect(proxy.relayed, greaterThanOrEqualTo(2));
    expect(origin.playlistHits, 1);
    expect(origin.segmentHits, 1);

    await engine.dispose();
  });

  test('clearing the proxy switches back to direct connections immediately',
      () async {
    final engine = buildEngine(
      EngineConfig(preferMp4: false, proxyHost: proxy.host, proxyPort: proxy.port),
    );

    // First request through the proxy.
    await engine.parseForPreview('${origin.baseUrl}/index.m3u8');
    final viaProxy = proxy.relayed;
    expect(viaProxy, greaterThanOrEqualTo(1));

    // User clears the host -> direct connection, no restart.
    engine.updateConfig(engine.config.copyWith(proxyHost: '', proxyPort: null));

    final originBefore = origin.playlistHits;
    await engine.parseForPreview('${origin.baseUrl}/index.m3u8');

    // The proxy saw no new traffic; the origin was hit directly.
    expect(proxy.relayed, viaProxy);
    expect(origin.playlistHits, originBefore + 1);

    await engine.dispose();
  });

  test('re-enabling the proxy after direct mode routes traffic again',
      () async {
    final engine = buildEngine(const EngineConfig(preferMp4: false));

    // Direct by default.
    await engine.parseForPreview('${origin.baseUrl}/index.m3u8');
    expect(proxy.relayed, 0);

    // Turn the proxy on at runtime.
    engine.updateConfig(
      engine.config.copyWith(proxyHost: proxy.host, proxyPort: proxy.port),
    );
    await engine.parseForPreview('${origin.baseUrl}/index.m3u8');
    expect(proxy.relayed, greaterThanOrEqualTo(1));

    await engine.dispose();
  });
}

/// Polls [condition] until true or a timeout elapses.
Future<void> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
