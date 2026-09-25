import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/core/platform/download_link_service.dart';
import 'package:stream_mediary/engine/download_engine.dart';
import 'package:stream_mediary/engine/engine_config.dart';
import 'package:stream_mediary/engine/engine_events.dart';
import 'package:stream_mediary/engine/m3u8/playlist.dart';
import 'package:stream_mediary/engine/net/roud_decoder.dart';
import 'package:stream_mediary/engine/net/segment_downloader.dart';

import 'in_memory_task_store.dart';

List<int> wrapped(List<int> payload, {bool compressed = true}) {
  final content = <int>[
    compressed ? 1 : 0,
    ...compressed ? zlib.encode(payload) : payload,
  ];
  final length = content.length;
  return <int>[
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    (length >> 24) & 255,
    (length >> 16) & 255,
    (length >> 8) & 255,
    length & 255,
    114,
    111,
    85,
    100,
    ...content,
    0,
    0,
    0,
    0,
  ];
}

void main() {
  test('extracts plain and compressed roUd chunks', () {
    expect(unwrapRoud(wrapped([1, 2, 3], compressed: false)), [1, 2, 3]);
    expect(unwrapRoud(wrapped([4, 5, 6])), [4, 5, 6]);
    final withLeadingChunk = wrapped([10, 11]);
    withLeadingChunk.insertAll(8, [0, 0, 0, 0, 73, 72, 68, 82, 0, 0, 0, 0]);
    expect(unwrapRoud(withLeadingChunk), [10, 11]);
    final raw = ZLibEncoder(raw: true).convert([7, 8, 9]);
    final rawWrapped = wrapped(raw, compressed: false);
    rawWrapped[16] = 1;
    expect(unwrapRoud(rawWrapped), [7, 8, 9]);
    expect(unwrapRoud([7, 8]), [7, 8]);
    expect(
      () => unwrapRoud(wrapped([1]).sublist(0, 17)),
      throwsFormatException,
    );
  });

  test('accepts desktop download link with headers', () {
    final link = DownloadLink.parse(
      'stream-mediary://download?url=https%3A%2F%2Frou.video%2Fapi%2Fhls%2Fid'
      '&referer=https%3A%2F%2Frou.video%2Fv%2Fid&userAgent=Chrome',
    );
    expect(link?.url, 'https://rou.video/api/hls/id');
    expect(link?.headers['Referer'], 'https://rou.video/v/id');
    expect(
      DownloadLink.parse('stream-mediary://download?url=file:///etc/passwd'),
      isNull,
    );
    final signed = DownloadLink.parse(
      'stream-mediary://download?url=https%3A%2F%2Fcdn.example%2Fmaster.png%3Fsig%3Da%252Bb'
      '&referer=https%3A%2F%2Frou.video%2Fv%2Fid&userAgent=Chrome',
    );
    expect(signed?.url, 'https://cdn.example/master.png?sig=a%2Bb');
    expect(signed?.headers['Referer'], 'https://rou.video/v/id');
  });

  test('applies byte ranges after PNG decoding', () async {
    final temp = await Directory.systemTemp.createTemp('roud-range-');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String?>[];
    final subscription = server.listen((request) async {
      requests.add(request.headers.value(HttpHeaders.rangeHeader));
      request.response.add(wrapped([0x47, 1, 2, 3, 4]));
      await request.response.close();
    });
    try {
      final target = File('${temp.path}/segment.ts');
      final result = await SegmentDownloader().download(
        'http://127.0.0.1:${server.port}/segment.png',
        targetFile: target,
        byteRange: const ByteRange(1, 3),
      );
      expect(result.success, isTrue);
      expect(requests, [null]);
      expect(await target.readAsBytes(), [1, 2, 3]);
    } finally {
      await subscription.cancel();
      await server.close(force: true);
      await temp.delete(recursive: true);
    }
  });

  test(
    'downloads signed PNG-wrapped master and segments without proxy',
    () async {
      final temp = await Directory.systemTemp.createTemp('roud-download-');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final base = 'http://127.0.0.1:${server.port}';
      final requested = <String>[];
      final subscription = server.listen((request) async {
        requested.add(request.uri.toString());
        if (request.uri.path == '/api/hls/id') {
          request.response.statusCode = 302;
          request.response.headers.set(
            HttpHeaders.locationHeader,
            '/cdn/master.png?sig=abc',
          );
        } else if (request.uri.query != 'sig=abc') {
          request.response.statusCode = 403;
        } else if (request.uri.path == '/cdn/master.png') {
          request.response.add(
            wrapped(
              '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1000\nmedia.png\n'
                  .codeUnits,
            ),
          );
        } else if (request.uri.path == '/cdn/media.png') {
          request.response.add(
            wrapped(
              '#EXTM3U\n#EXTINF:1,\nseg0.png\n#EXTINF:1,\nseg1.png\n#EXT-X-ENDLIST\n'
                  .codeUnits,
            ),
          );
        } else if (request.uri.path == '/cdn/seg0.png') {
          request.response.add(wrapped([0x47, 1, 2], compressed: false));
        } else if (request.uri.path == '/cdn/seg1.png') {
          request.response.add(wrapped([0x47, 3, 4]));
        } else {
          request.response.statusCode = 404;
        }
        await request.response.close();
      });
      final engine = DownloadEngine(
        store: InMemoryTaskStore(),
        config: const EngineConfig(preferMp4: false),
        defaultSaveDir: temp.path,
      );
      try {
        final master = await engine.parseForPreview('$base/api/hls/id');
        expect(master, isA<MasterParseResult>());
        final variant =
            (master as MasterParseResult).master.variants.single.url;
        expect(variant, '$base/cdn/media.png?sig=abc');
        final result = await engine.parseForPreview(variant);
        final playlist = (result as MediaParseResult).media;
        expect(playlist.segments.map((s) => s.url), [
          '$base/cdn/seg0.png?sig=abc',
          '$base/cdn/seg1.png?sig=abc',
        ]);
        final completed = engine.events
            .where((event) => event is TaskCompletedEvent)
            .cast<TaskCompletedEvent>()
            .first;
        await engine.startTask(
          id: 'wrapped',
          request: DownloadRequest(url: variant, sourceUrl: '$base/api/hls/id'),
          playlist: playlist,
        );
        final event = await completed.timeout(const Duration(seconds: 15));
        expect(await File(event.outputPath).readAsBytes(), [
          0x47,
          1,
          2,
          0x47,
          3,
          4,
        ]);
        expect(requested.where((path) => path.contains('/cdn/seg')).length, 2);
      } finally {
        engine.dispose();
        await subscription.cancel();
        await server.close(force: true);
        await temp.delete(recursive: true);
      }
    },
  );
}
