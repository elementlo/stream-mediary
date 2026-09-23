/// The core download engine.
///
/// Pure Dart (no Flutter dependency). Orchestrates the full pipeline:
/// parse playlist -> schedule segment downloads -> decrypt -> merge.
/// Emits [EngineEvent]s on [events] and persists state via [EngineTaskStore].
library;

// The public constructor keeps the named `store` and `config` API while
// assigning them to private fields.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'crypto/aes_decryptor.dart';
import 'engine_config.dart';
import 'engine_events.dart';
import 'engine_store.dart';
import 'm3u8/m3u8_parser.dart';
import 'm3u8/playlist.dart';
import 'merge/ffmpeg_remuxer.dart';
import 'merge/ts_merger.dart';
import 'net/segment_downloader.dart';
import 'scheduler/segment_scheduler.dart';
import 'task/task_runtime.dart';
import 'task/task_state.dart';

final Logger _log = Logger('DownloadEngine');

class DownloadEngine {
  DownloadEngine({
    required EngineTaskStore store,
    EngineConfig config = const EngineConfig(),
    Dio? dio,
    this.defaultSaveDir,
  }) : _store = store,
       _config = config,
       _dio = dio ?? Dio();

  final EngineTaskStore _store;
  EngineConfig _config;
  final Dio _dio;

  /// Directory used when a request does not specify one.
  String? defaultSaveDir;

  final M3u8Parser _parser = const M3u8Parser();
  final SegmentDownloader _downloader = SegmentDownloader();
  final TsMerger _merger = const TsMerger();
  final FfmpegRemuxer _remuxer = const FfmpegRemuxer();

  final Map<String, TaskRuntime> _runtimes = {};
  final StreamController<EngineEvent> _events =
      StreamController<EngineEvent>.broadcast();

  /// Task-level concurrency limiter.
  final _TaskSemaphore _taskSemaphore = _TaskSemaphore(3);
  void setQueueAllowed(bool allowed) {
    _taskSemaphore.allowed = allowed;
  }

  /// Broadcast stream of engine events.
  Stream<EngineEvent> get events => _events.stream;

  EngineConfig get config => _config;

  /// Applies new configuration (from settings).
  void updateConfig(EngineConfig config) {
    _config = config;
    _taskSemaphore.limit = config.taskConcurrency;
  }

  void _emit(EngineEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  // ---------------------------------------------------------------------------
  // Parsing / preview
  // ---------------------------------------------------------------------------

  /// Fetches and parses [url], returning the parse result for preview.
  ///
  /// Does not create a persisted task. Used by the "new download" flow.
  Future<ParseResult> parseForPreview(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    final content = await _fetchPlaylistText(url, headers);
    return _parser.parse(content, playlistUrl: url);
  }

  /// Best-effort estimate. A byte-range playlist is exact; otherwise sample
  /// three segment response lengths and scale by the playlist duration.
  Future<int?> estimateMediaBytes(
    MediaPlaylist playlist, {
    Map<String, String> headers = const {},
  }) async {
    if (playlist.segments.isEmpty) return null;
    if (playlist.segments.every((s) => s.byteRange != null)) {
      return playlist.segments.fold<int>(
        0,
        (sum, s) => sum + s.byteRange!.length,
      );
    }
    final segments = playlist.segments;
    final indexes = {0, segments.length ~/ 2, segments.length - 1};
    var sampledBytes = 0;
    var sampledDuration = 0.0;
    for (final index in indexes) {
      final segment = segments[index];
      try {
        final response = await _dio.head<void>(
          segment.url,
          options: Options(
            headers: headers,
            receiveTimeout: const Duration(seconds: 8),
          ),
        );
        final length = int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        );
        if (length == null || length <= 0 || segment.duration <= 0) continue;
        sampledBytes += length;
        sampledDuration += segment.duration;
      } catch (_) {
        // Some hosts reject HEAD; the estimate simply remains unavailable.
      }
    }
    if (sampledDuration <= 0) return null;
    return (sampledBytes * playlist.totalDuration / sampledDuration).round();
  }

  Future<String> _fetchPlaylistText(
    String url,
    Map<String, String> headers,
  ) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: headers,
        followRedirects: true,
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return utf8.decode(response.data ?? const [], allowMalformed: true);
  }

  // ---------------------------------------------------------------------------
  // Task lifecycle
  // ---------------------------------------------------------------------------

  /// Creates and starts a download task from a confirmed request.
  ///
  /// [playlist] is the already-parsed media playlist (from preview). The task
  /// is persisted and immediately scheduled.
  Future<String> startTask({
    required String id,
    required DownloadRequest request,
    required MediaPlaylist playlist,
  }) async {
    if (playlist.isLive) {
      throw const M3u8ParseException('Live recording is not supported');
    }
    final saveDir = await _resolveSaveDir(request.saveDir);
    final now = DateTime.now().millisecondsSinceEpoch;
    final title = await _uniqueTitle(request.effectiveTitle);

    final record = EngineTaskRecord(
      id: id,
      url: request.url,
      sourceUrl: request.sourceUrl ?? request.url,
      title: title,
      state: TaskState.queued,
      headers: request.headers,
      customKeyHex: request.customKeyHex,
      customIvHex: request.customIvHex,
      playlistSnapshot: jsonEncode(playlist.toJson()),
      saveDir: saveDir,
      totalSegments: playlist.segmentCount,
      queueOrder: now,
      createdAt: now,
      updatedAt: now,
    );
    await _store.saveTask(record);

    final segmentRecords = playlist.segments
        .map((s) => EngineSegmentRecord(taskId: id, seq: s.seq, url: s.url))
        .toList();
    await _store.saveSegments(segmentRecords);

    final runtime = TaskRuntime(taskId: id)
      ..playlist = playlist
      ..state = TaskState.queued
      ..totalSegments = playlist.segmentCount;
    _runtimes[id] = runtime;

    _emit(TaskStateChangedEvent(taskId: id, state: TaskState.queued));
    unawaited(_runTask(record, runtime));
    return id;
  }

  Future<void> _runTask(EngineTaskRecord record, TaskRuntime runtime) async {
    // Acquire a task-level concurrency slot before downloading.
    final admitted = await _taskSemaphore.acquire(record.id, record.queueOrder);
    if (!admitted) return;
    if (runtime.state == TaskState.paused ||
        runtime.state == TaskState.canceled) {
      _taskSemaphore.release();
      return;
    }
    try {
      await _setState(record, runtime, TaskState.downloading);
      await _downloadAllSegments(record, runtime);

      if (runtime.state == TaskState.canceled ||
          runtime.state == TaskState.paused) {
        return;
      }

      await _setState(record, runtime, TaskState.merging);
      final output = await _merge(record, runtime);

      record.outputPath = output.path;
      await _setState(record, runtime, TaskState.completed);
      _emit(TaskCompletedEvent(taskId: record.id, outputPath: output.path));
    } catch (e, st) {
      _log.severe('Task ${record.id} failed', e, st);
      record.errorMsg = '$e';
      await _setState(record, runtime, TaskState.failed, error: '$e');
      _emit(ErrorOccurredEvent(taskId: record.id, message: '$e'));
    } finally {
      _taskSemaphore.release();
    }
  }

  Future<void> _setState(
    EngineTaskRecord record,
    TaskRuntime runtime,
    TaskState to, {
    String? error,
  }) async {
    if (!canTransition(runtime.state, to)) {
      _log.warning('Illegal transition ${runtime.state} -> $to (ignored)');
      return;
    }
    runtime.state = to;
    record.state = to;
    record.errorMsg = error;
    record.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _store.saveTask(record);
    _emit(TaskStateChangedEvent(taskId: record.id, state: to, error: error));
  }

  // ---------------------------------------------------------------------------
  // Segment downloading
  // ---------------------------------------------------------------------------

  Future<void> _downloadAllSegments(
    EngineTaskRecord record,
    TaskRuntime runtime,
  ) async {
    final playlist = runtime.playlist!;
    final taskDir = _taskDir(record);
    final segmentsDir = Directory(p.join(taskDir, 'segments'));
    await segmentsDir.create(recursive: true);

    // Restore: mark already-downloaded segments as done.
    final existing = await _store.loadSegments(record.id);
    final doneSeqs = <int>{};
    for (final seg in existing) {
      final file = _segmentFile(segmentsDir, seg.seq);
      if (seg.status == SegmentStatus.done &&
          file.existsSync() &&
          file.lengthSync() == seg.byteSize &&
          seg.byteSize > 0) {
        doneSeqs.add(seg.seq);
        runtime.doneSegments++;
        runtime.downloadedBytes += seg.byteSize;
      }
    }
    runtime.totalBytes = await _estimateTotalBytes(playlist, existing);

    final pending = playlist.segments
        .where((s) => !doneSeqs.contains(s.seq))
        .toList();
    final failures = <int, String>{};

    final scheduler = SegmentScheduler(concurrency: _config.segmentConcurrency);
    runtime.scheduler = scheduler;

    scheduler.onJobDone = (seq, success, wasCanceled) {
      if (success) {
        runtime.doneSegments++;
        final file = _segmentFile(segmentsDir, seq);
        final size = file.existsSync() ? file.lengthSync() : 0;
        runtime.downloadedBytes += size;
        // Estimate total size from the average of completed segments so the
        // progress bar and speed are meaningful before all sizes are known.
        if (runtime.doneSegments > 0 && runtime.totalSegments > 0) {
          runtime.totalBytes =
              runtime.downloadedBytes *
              runtime.totalSegments ~/
              runtime.doneSegments;
        }
        runtime.sampleSpeed();
        _emitProgress(record, runtime);
        unawaited(_markSegment(record.id, seq, SegmentStatus.done, size));
      } else if (!wasCanceled) {
        unawaited(_markSegment(record.id, seq, SegmentStatus.failed, 0));
      }
    };

    final jobs = pending.map((segment) {
      return SchedulerJob(
        seq: segment.seq,
        run: (token) async {
          final target = _segmentFile(segmentsDir, segment.seq);
          final result = await _downloader.download(
            segment.url,
            targetFile: target,
            headers: record.headers,
            cancelToken: token,
            byteRange: segment.byteRange,
          );
          if (!result.success) {
            failures[segment.seq] = result.error ?? 'download failed';
            return false;
          }

          // Decrypt in place if needed.
          if (segment.keyInfo?.encrypted == true) {
            await _decryptSegmentFile(record, runtime, segment, target);
          }
          return true;
        },
      );
    }).toList();

    scheduler.submit(jobs);
    await scheduler.drained;

    if (scheduler.isPaused ||
        runtime.state == TaskState.paused ||
        runtime.state == TaskState.canceled) {
      return;
    }

    // Verify all segments present.
    final missing = playlist.segments
        .where((s) => !_segmentFile(segmentsDir, s.seq).existsSync())
        .toList();
    if (missing.isNotEmpty) {
      final cause = failures[missing.first.seq] ?? 'unknown';
      throw StateError('${missing.length} segments failed to download: $cause');
    }
  }

  Future<int> _estimateTotalBytes(
    MediaPlaylist playlist,
    List<EngineSegmentRecord> existing,
  ) async {
    var total = 0;
    for (final seg in existing) {
      total += seg.byteSize;
    }
    return total;
  }

  File _segmentFile(Directory segmentsDir, int seq) =>
      File(p.join(segmentsDir.path, '${seq.toString().padLeft(6, '0')}.ts'));

  String _taskDir(EngineTaskRecord record) => record.outputPath != null
      ? p.dirname(record.outputPath!)
      : p.join(record.saveDir, _sanitize(record.title));

  /// Resolves a writable save directory.
  ///
  /// Prefers the user-chosen directory, falling back to the configured
  /// default and finally the app documents directory when the chosen path
  /// cannot be created/written (e.g. a SAF URI without write permission).
  Future<String> _resolveSaveDir(String? requested) async {
    final candidates = <String>[
      if (requested != null && requested.isNotEmpty) requested,
      if (defaultSaveDir != null && defaultSaveDir!.isNotEmpty) defaultSaveDir!,
    ];
    for (final dir in candidates) {
      try {
        final d = Directory(dir);
        await d.create(recursive: true);
        final probe = File(p.join(d.path, '.write_probe'));
        await probe.writeAsString('ok');
        await probe.delete();
        return dir;
      } catch (_) {
        _log.warning('Save dir not writable, trying next: $dir');
      }
    }
    throw const FileSystemException('No writable save directory');
  }

  String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();

  /// Ensures the task title maps to a unique on-disk directory.
  ///
  /// Two downloads of the same playlist would otherwise share one folder
  /// (`saveDir/<title>`) and overwrite each other's output. When a title is
  /// already taken by another task, a ` (2)`, ` (3)` … suffix is appended.
  Future<String> _uniqueTitle(String base) async {
    final sanitizedBase = _sanitize(base);
    final existing = await _store.loadAllTasks();
    final taken = existing.map((t) => _sanitize(t.title)).toSet();
    if (!taken.contains(sanitizedBase)) return sanitizedBase;

    var n = 2;
    var candidate = '$sanitizedBase ($n)';
    while (taken.contains(candidate)) {
      n++;
      candidate = '$sanitizedBase ($n)';
    }
    return candidate;
  }

  Future<void> _markSegment(
    String taskId,
    int seq,
    SegmentStatus status,
    int size,
  ) async {
    final segments = await _store.loadSegments(taskId);
    for (final seg in segments) {
      if (seg.seq == seq) {
        seg.status = status;
        if (size > 0) seg.byteSize = size;
        await _store.saveSegments([seg]);
        break;
      }
    }
  }

  void _emitProgress(EngineTaskRecord record, TaskRuntime runtime) {
    record.doneSegments = runtime.doneSegments;
    record.downloadedBytes = runtime.downloadedBytes;
    _emit(
      ProgressEvent(
        taskId: record.id,
        doneSegments: runtime.doneSegments,
        totalSegments: runtime.totalSegments,
        downloadedBytes: runtime.downloadedBytes,
        totalBytes: runtime.totalBytes,
        bytesPerSecond: runtime.bytesPerSecond,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Decryption
  // ---------------------------------------------------------------------------

  Future<void> _decryptSegmentFile(
    EngineTaskRecord record,
    TaskRuntime runtime,
    Segment segment,
    File file,
  ) async {
    final keyInfo = segment.keyInfo!;
    final key = await _resolveKey(record, runtime, keyInfo);
    final iv = _resolveIv(record, keyInfo, segment.seq);

    final input = file.openRead();
    final decrypted = decryptSegmentStream(input, key: key, iv: iv);

    final tmp = File('${file.path}.dec');
    final sink = tmp.openWrite();
    try {
      await for (final chunk in decrypted) {
        sink.add(chunk);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    await tmp.rename(file.path);
  }

  Future<Uint8List> _resolveKey(
    EngineTaskRecord record,
    TaskRuntime runtime,
    KeyInfo keyInfo,
  ) async {
    // User-provided key takes precedence.
    if (record.customKeyHex != null && record.customKeyHex!.isNotEmpty) {
      return hexToBytes(record.customKeyHex!);
    }

    final uri = keyInfo.uri;
    if (uri == null) {
      throw const AesDecryptException('Encrypted segment has no key URI');
    }

    final cached = runtime.keyCache[uri];
    if (cached != null) return Uint8List.fromList(cached);

    final response = await _dio.get<List<int>>(
      uri,
      options: Options(
        responseType: ResponseType.bytes,
        headers: record.headers,
      ),
      cancelToken: runtime.cancelToken,
    );
    final keyBytes = response.data ?? const [];
    runtime.keyCache[uri] = keyBytes;
    return Uint8List.fromList(keyBytes);
  }

  Uint8List _resolveIv(EngineTaskRecord record, KeyInfo keyInfo, int seq) {
    if (record.customIvHex != null && record.customIvHex!.isNotEmpty) {
      return hexToBytes(record.customIvHex!);
    }
    if (keyInfo.ivHex != null && keyInfo.ivHex!.isNotEmpty) {
      return hexToBytes(keyInfo.ivHex!);
    }
    return defaultIvForSequence(seq);
  }

  // ---------------------------------------------------------------------------
  // Merging
  // ---------------------------------------------------------------------------

  Future<File> _merge(EngineTaskRecord record, TaskRuntime runtime) async {
    final playlist = runtime.playlist!;
    final taskDir = _taskDir(record);
    final segmentsDir = Directory(p.join(taskDir, 'segments'));

    final segmentFiles = playlist.segments
        .map((s) => _segmentFile(segmentsDir, s.seq))
        .toList();

    final init = playlist.initializationSection;
    if (init != null) {
      final initFile = File(p.join(taskDir, 'initialization.part.media'));
      final downloaded = await _downloader.download(
        init.url,
        targetFile: initFile,
        headers: record.headers,
        byteRange: init.byteRange,
      );
      if (!downloaded.success) {
        throw StateError(
          'Initialization section download failed: ${downloaded.error}',
        );
      }
      segmentFiles.insert(0, initFile);
    }

    final tsOutput = File(
      p.join(
        taskDir,
        '${_sanitize(record.title)}.${init == null ? 'ts' : 'mp4'}',
      ),
    );

    await _merger.merge(
      segmentFiles,
      outputFile: tsOutput,
      onProgress: (written, total) {
        _emit(
          MergeProgressEvent(
            taskId: record.id,
            writtenBytes: written,
            totalBytes: total,
          ),
        );
      },
    );

    File finalOutput = tsOutput;
    if (_config.preferMp4 && init == null) {
      final mp4 = await _remuxer.remuxToMp4(
        tsOutput,
        ffmpegPath: _config.ffmpegPath,
      );
      if (mp4 != null) {
        finalOutput = mp4;
        // Keep the .ts as well? Remove to save space.
        try {
          await tsOutput.delete();
        } on FileSystemException {
          // Ignore.
        }
      }
    }

    // Segments are fully merged; free the disk space.
    try {
      await segmentsDir.delete(recursive: true);
    } on FileSystemException {
      // Ignore.
    }

    return finalOutput;
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  /// Pauses an active task.
  Future<void> pauseTask(String id) async {
    final runtime = _runtimes[id];
    if (runtime == null) return;
    runtime.scheduler?.cancel();
    runtime.scheduler = null;
    _taskSemaphore.cancel(id);
    final record = await _store.loadTask(id);
    if (record != null) {
      await _setState(record, runtime, TaskState.paused);
    }
  }

  /// Resumes a paused task.
  Future<void> resumeTask(String id) async {
    final record = await _store.loadTask(id);
    if (record == null) return;

    // Rebuild a scheduler so the paused task does not occupy a concurrency slot.
    await _coldResume(record);
  }

  /// Cancels a task and cleans up its files.
  Future<void> cancelTask(String id, {bool deleteFiles = true}) async {
    _taskSemaphore.cancel(id);
    final runtime = _runtimes[id];
    runtime?.scheduler?.cancel();
    runtime?.cancelToken.cancel('canceled');

    final record = await _store.loadTask(id);
    if (record != null) {
      if (runtime != null) {
        runtime.state = TaskState.canceled;
      }
      record.state = TaskState.canceled;
      record.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _store.saveTask(record);
      _emit(TaskStateChangedEvent(taskId: id, state: TaskState.canceled));

      if (deleteFiles) {
        final dir = Directory(_taskDir(record));
        if (await dir.exists()) {
          try {
            await dir.delete(recursive: true);
          } on FileSystemException {
            // Ignore.
          }
        }
      }
    }
    _runtimes.remove(id);
  }

  /// Deletes a task record and, optionally, its files on disk.
  ///
  /// Used by the history page. When [deleteFiles] is true the whole task
  /// directory (`saveDir/<title>`, containing the merged output and any
  /// leftover segments) is removed.
  Future<void> removeTask(String id, {bool deleteFiles = false}) async {
    final record = await _store.loadTask(id);
    if (record != null && deleteFiles) {
      final dir = Directory(_taskDir(record));
      if (await dir.exists()) {
        try {
          await dir.delete(recursive: true);
        } on FileSystemException {
          // Ignore: the record is removed regardless.
        }
      }
    }
    await _store.deleteTask(id);
    _runtimes.remove(id);
  }

  /// Retries a failed or canceled task from scratch (reuses done segments).
  Future<void> retryTask(String id) async {
    final record = await _store.loadTask(id);
    if (record == null) return;
    if (record.state != TaskState.failed &&
        record.state != TaskState.canceled) {
      return;
    }

    final snapshot = record.playlistSnapshot;
    if (snapshot == null) return;
    final playlist = MediaPlaylist.fromJson(
      jsonDecode(snapshot) as Map<String, dynamic>,
    );

    final runtime = TaskRuntime(taskId: id)
      ..playlist = playlist
      ..state = TaskState.queued
      ..totalSegments = playlist.segmentCount;
    _runtimes[id] = runtime;

    record.state = TaskState.queued;
    record.queueOrder = DateTime.now().microsecondsSinceEpoch;
    record.errorMsg = null;
    await _store.saveTask(record);
    _emit(TaskStateChangedEvent(taskId: id, state: TaskState.queued));
    unawaited(_runTask(record, runtime));
  }

  /// Creates a separate task for an already completed download.
  Future<String> redownloadTask(String id, String newId) async {
    final record = await _store.loadTask(id);
    if (record == null || record.playlistSnapshot == null) {
      throw StateError('The original download cannot be recreated');
    }
    final playlist = MediaPlaylist.fromJson(
      jsonDecode(record.playlistSnapshot!) as Map<String, dynamic>,
    );
    return startTask(
      id: newId,
      request: DownloadRequest(
        url: record.url,
        sourceUrl: record.sourceUrl,
        title: record.title,
        headers: record.headers,
        customKeyHex: record.customKeyHex,
        customIvHex: record.customIvHex,
        saveDir: record.saveDir,
      ),
      playlist: playlist,
    );
  }

  Future<void> moveQueuedTask(String id, {required bool first}) async {
    final record = await _store.loadTask(id);
    if (record == null || record.state != TaskState.queued) return;
    final tasks = await _store.loadAllTasks();
    final orders = tasks
        .where((t) => t.state == TaskState.queued)
        .map((t) => t.queueOrder)
        .toList();
    if (orders.isEmpty) return;
    record.queueOrder = first
        ? orders.reduce((a, b) => a < b ? a : b) - 1
        : orders.reduce((a, b) => a > b ? a : b) + 1;
    await _store.saveTask(record);
    _taskSemaphore.reorder(id, record.queueOrder);
  }

  /// Replace an expired source. Existing bytes are reused only when every
  /// segment URL, range and key remains identical; otherwise they are removed.
  Future<void> replaceExpiredSource(
    String id,
    String sourceUrl, {
    Map<String, String>? headers,
  }) async {
    final record = await _store.loadTask(id);
    if (record == null || record.state != TaskState.failed) {
      throw StateError('Only failed tasks can replace their source');
    }
    final nextHeaders = headers ?? record.headers;
    final parsed = await parseForPreview(sourceUrl, headers: nextHeaders);
    final String mediaUrl;
    final MediaPlaylist playlist;
    if (parsed is MasterParseResult) {
      mediaUrl = parsed.master.variants.first.url;
      final child = await parseForPreview(mediaUrl, headers: nextHeaders);
      if (child is! MediaParseResult) {
        throw const M3u8ParseException(
          'Selected variant is not a media playlist',
        );
      }
      playlist = child.media;
    } else {
      mediaUrl = sourceUrl;
      playlist = (parsed as MediaParseResult).media;
    }
    if (playlist.isLive) {
      throw const M3u8ParseException('Live recording is not supported');
    }
    final old = record.playlistSnapshot == null
        ? null
        : MediaPlaylist.fromJson(
            jsonDecode(record.playlistSnapshot!) as Map<String, dynamic>,
          );
    final identical = old != null && _sameMedia(old, playlist);
    if (!identical) {
      final segmentsDir = Directory(p.join(_taskDir(record), 'segments'));
      if (await segmentsDir.exists()) await segmentsDir.delete(recursive: true);
      await _store.deleteSegments(id);
      record.doneSegments = 0;
      record.downloadedBytes = 0;
      record.totalBytes = 0;
    }
    record.url = mediaUrl;
    record.sourceUrl = sourceUrl;
    record.headers = nextHeaders;
    record.playlistSnapshot = jsonEncode(playlist.toJson());
    record.totalSegments = playlist.segmentCount;
    record.errorMsg = null;
    await _store.saveTask(record);
    if (!identical) {
      await _store.saveSegments(
        playlist.segments
            .map((s) => EngineSegmentRecord(taskId: id, seq: s.seq, url: s.url))
            .toList(),
      );
    }
    await retryTask(id);
  }

  bool _sameMedia(MediaPlaylist a, MediaPlaylist b) {
    if (a.segments.length != b.segments.length ||
        jsonEncode(a.initializationSection?.toJson()) !=
            jsonEncode(b.initializationSection?.toJson())) {
      return false;
    }
    for (var i = 0; i < a.segments.length; i++) {
      final first = a.segments[i];
      final second = b.segments[i];
      if (first.seq != second.seq ||
          first.url != second.url ||
          first.keyInfo != second.keyInfo ||
          jsonEncode(first.byteRange?.toJson()) !=
              jsonEncode(second.byteRange?.toJson())) {
        return false;
      }
    }
    return true;
  }

  Future<void> renameTask(String id, String title) async {
    final record = await _store.loadTask(id);
    if (record == null ||
        record.state != TaskState.completed ||
        title.trim().isEmpty) {
      return;
    }
    record.title = title.trim();
    record.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _store.saveTask(record);
  }

  Future<void> savePlayback(
    String id,
    Duration position,
    Duration duration,
  ) async {
    final record = await _store.loadTask(id);
    if (record == null) return;
    record.playbackMs = position.inMilliseconds;
    record.durationMs = duration.inMilliseconds;
    await _store.saveTask(record);
  }

  /// Restores unfinished tasks after app restart (cold resume).
  Future<void> restoreUnfinished() async {
    final all = await _store.loadAllTasks();
    for (final record in all) {
      final resumable =
          record.state == TaskState.downloading ||
          record.state == TaskState.queued;
      if (resumable) {
        await _coldResume(record);
      }
    }
  }

  Future<void> _coldResume(EngineTaskRecord record) async {
    final snapshot = record.playlistSnapshot;
    if (snapshot == null) return;
    final playlist = MediaPlaylist.fromJson(
      jsonDecode(snapshot) as Map<String, dynamic>,
    );

    final runtime = TaskRuntime(taskId: record.id)
      ..playlist = playlist
      ..state = TaskState.queued
      ..totalSegments = playlist.segmentCount;
    _runtimes[record.id] = runtime;

    record.state = TaskState.queued;
    await _store.saveTask(record);
    _emit(TaskStateChangedEvent(taskId: record.id, state: TaskState.queued));
    unawaited(_runTask(record, runtime));
  }

  /// Disposes the engine, canceling all in-flight work.
  Future<void> dispose() async {
    for (final runtime in _runtimes.values) {
      runtime.scheduler?.cancel();
      runtime.cancelToken.cancel('disposed');
    }
    await _events.close();
  }
}

/// A simple counting semaphore used to bound task-level concurrency.
class _TaskSemaphore {
  _TaskSemaphore(this._limit);

  int _limit;
  int get limit => _limit;
  set limit(int value) {
    _limit = value;
    _pump();
  }

  int _inUse = 0;
  bool _allowed = true;
  final List<_TaskWaiter> _waiters = [];

  set allowed(bool value) {
    _allowed = value;
    _pump();
  }

  Future<bool> acquire(String id, int order) {
    final waiter = _TaskWaiter(id, order);
    _waiters.add(waiter);
    _pump();
    return waiter.completer.future;
  }

  void release() {
    if (_inUse > 0) _inUse--;
    _pump();
  }

  void cancel(String id) {
    for (final waiter in _waiters.where((w) => w.id == id).toList()) {
      _waiters.remove(waiter);
      waiter.completer.complete(false);
    }
  }

  void reorder(String id, int order) {
    for (final waiter in _waiters.where((w) => w.id == id)) {
      waiter.order = order;
    }
    _pump();
  }

  void _pump() {
    if (!_allowed) return;
    _waiters.sort((a, b) => a.order.compareTo(b.order));
    while (_inUse < limit && _waiters.isNotEmpty) {
      _inUse++;
      _waiters.removeAt(0).completer.complete(true);
    }
  }
}

class _TaskWaiter {
  _TaskWaiter(this.id, this.order);
  final String id;
  int order;
  final Completer<bool> completer = Completer<bool>();
}
