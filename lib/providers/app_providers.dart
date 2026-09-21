import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../data/db/app_database.dart';
import '../data/remote/waline_client.dart';
import '../data/repositories/board_cache.dart';
import '../data/repositories/drift_engine_task_store.dart';
import '../data/repositories/settings_repository.dart';
import '../engine/download_engine.dart';
import '../engine/engine_events.dart';
import '../engine/engine_store.dart';
import '../engine/task/task_state.dart';

/// Singleton application database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final settingsRepositoryProvider = Provider<SettingsRepository>(
    (ref) => SettingsRepository(ref.watch(appDatabaseProvider)));

final engineTaskStoreProvider = Provider<EngineTaskStore>(
    (ref) => DriftEngineTaskStore(ref.watch(appDatabaseProvider)));

/// Default save directory resolved per platform.
final defaultSaveDirProvider = FutureProvider<String>((ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  final configured = await settings.defaultSaveDir();
  if (configured != null && configured.isNotEmpty) return configured;

  if (Platform.isAndroid) {
    // App-specific external dir is user-visible and needs no permission.
    final ext = await getExternalStorageDirectory();
    if (ext != null) return ext.path;
  }

  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
});

/// The download engine, configured from settings.
final downloadEngineProvider = Provider<DownloadEngine>((ref) {
  final store = ref.watch(engineTaskStoreProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  final engine = DownloadEngine(store: store);
  ref.onDispose(engine.dispose);

  // Apply persisted settings (concurrency, merge preference, ffmpeg path,
  // default save dir) once the database is readable.
  Future.microtask(() async {
    final (taskConcurrency, segmentConcurrency, merge, ffmpegPath, saveDir) =
        await (
      settings.taskConcurrency(),
      settings.segmentConcurrency(),
      settings.mergePreference(),
      settings.ffmpegPath(),
      ref.read(defaultSaveDirProvider.future),
    ).wait;
    engine.updateConfig(engine.config.copyWith(
      taskConcurrency: taskConcurrency,
      segmentConcurrency: segmentConcurrency,
      preferMp4: merge == 'prefer_mp4',
      ffmpegPath: ffmpegPath,
    ));
    engine.defaultSaveDir = saveDir;
  });

  return engine;
});

/// Live task view model surfaced to the UI.
class TaskViewModel {
  const TaskViewModel({
    required this.id,
    required this.title,
    required this.url,
    required this.state,
    this.doneSegments = 0,
    this.totalSegments = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.bytesPerSecond = 0,
    this.mergeFraction = 0,
    this.outputPath,
    this.errorMsg,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String url;
  final TaskState state;
  final int doneSegments;
  final int totalSegments;
  final int downloadedBytes;
  final int totalBytes;
  final double bytesPerSecond;
  final double mergeFraction;
  final String? outputPath;
  final String? errorMsg;
  final int createdAt;

  double get downloadFraction =>
      totalBytes <= 0 ? 0 : downloadedBytes / totalBytes;

  TaskViewModel copyWith({
    TaskState? state,
    int? doneSegments,
    int? totalSegments,
    int? downloadedBytes,
    int? totalBytes,
    double? bytesPerSecond,
    double? mergeFraction,
    String? outputPath,
    String? errorMsg,
  }) =>
      TaskViewModel(
        id: id,
        title: title,
        url: url,
        state: state ?? this.state,
        doneSegments: doneSegments ?? this.doneSegments,
        totalSegments: totalSegments ?? this.totalSegments,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        totalBytes: totalBytes ?? this.totalBytes,
        bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
        mergeFraction: mergeFraction ?? this.mergeFraction,
        outputPath: outputPath ?? this.outputPath,
        errorMsg: errorMsg,
        createdAt: createdAt,
      );
}

/// Notifier maintaining the live map of task view models, fed by both the
/// persisted database stream and engine events.
class TaskListNotifier extends Notifier<Map<String, TaskViewModel>> {
  StreamSubscription<List<Task>>? _dbSub;
  StreamSubscription<EngineEvent>? _eventSub;

  @override
  Map<String, TaskViewModel> build() {
    final db = ref.watch(appDatabaseProvider);
    final engine = ref.watch(downloadEngineProvider);

    _dbSub?.cancel();
    _dbSub = db.watchAllTasks().listen((rows) {
      final next = <String, TaskViewModel>{};
      for (final row in rows) {
        next[row.id] = TaskViewModel(
          id: row.id,
          title: row.title,
          url: row.url,
          state: TaskState.values[row.status],
          doneSegments: row.doneSegments,
          totalSegments: row.totalSegments,
          downloadedBytes: row.downloadedBytes,
          totalBytes: row.totalBytes,
          outputPath: row.outputPath,
          errorMsg: row.errorMsg,
          createdAt: row.createdAt,
        );
      }
      state = next;
    });

    _eventSub?.cancel();
    _eventSub = engine.events.listen(_onEngineEvent);

    ref.onDispose(() {
      _dbSub?.cancel();
      _eventSub?.cancel();
    });

    // Restore unfinished tasks on startup.
    Future.microtask(engine.restoreUnfinished);

    // Initial state; the database stream above populates it shortly after.
    // (Reading `state` inside build is illegal in Riverpod 3.)
    return const {};
  }

  void _onEngineEvent(EngineEvent event) {
    final current = state[event.taskId];
    if (current == null) return;

    switch (event) {
      case TaskStateChangedEvent():
        state = {
          ...state,
          event.taskId: current.copyWith(
            state: event.state,
            errorMsg: event.error,
          ),
        };
      case ProgressEvent():
        state = {
          ...state,
          event.taskId: current.copyWith(
            doneSegments: event.doneSegments,
            totalSegments: event.totalSegments,
            downloadedBytes: event.downloadedBytes,
            totalBytes: event.totalBytes,
            bytesPerSecond: event.bytesPerSecond,
          ),
        };
      case MergeProgressEvent():
        state = {
          ...state,
          event.taskId: current.copyWith(mergeFraction: event.fraction),
        };
      case TaskCompletedEvent():
        state = {
          ...state,
          event.taskId: current.copyWith(
            state: TaskState.completed,
            outputPath: event.outputPath,
          ),
        };
      case ErrorOccurredEvent():
        state = {
          ...state,
          event.taskId: current.copyWith(errorMsg: event.message),
        };
    }
  }
}

final taskListProvider =
    NotifierProvider<TaskListNotifier, Map<String, TaskViewModel>>(
        TaskListNotifier.new);

/// Waline client for the community board. The server URL is hardcoded in
/// [WalineClient.defaultServerUrl]; there is nothing for users to configure.
final walineClientProvider = Provider<WalineClient>(
  (ref) => WalineClient(serverUrl: WalineClient.defaultServerUrl),
);

/// First page of board comments, fetched once at app startup and written
/// through to the drift cache.
///
/// Shared between the startup prefetch and the board page: opening the page
/// awaits this same future instead of issuing a second request, so the two
/// never duplicate each other. Manual refreshes invalidate it first.
final boardPrefetchProvider = FutureProvider<WalineCommentPage>((ref) async {
  final client = ref.read(walineClientProvider);
  final db = ref.read(appDatabaseProvider);
  final page = await client.fetchComments(page: 1);
  await cacheComments(db, page.comments);
  return page;
});

/// Nickname remembered between board posts.
final boardNickProvider = FutureProvider<String>((ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  return await settings.boardNick() ?? '';
});

/// App version string from the build metadata (pubspec `version`).
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// Theme mode backed by settings.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final settings = ref.read(settingsRepositoryProvider);
    final mode = await settings.themeMode();
    state = _parse(mode);
  }

  ThemeMode _parse(String mode) => switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final settings = ref.read(settingsRepositoryProvider);
    await settings.setThemeMode(switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
  }
}
