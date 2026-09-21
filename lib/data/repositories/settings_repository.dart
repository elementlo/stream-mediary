import 'dart:async';

import '../db/app_database.dart';

/// Application settings keys and typed access over the settings table.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const String keyConcurrency = 'task_concurrency';
  static const String keySegmentConcurrency = 'segment_concurrency';
  static const String keyDefaultSaveDir = 'default_save_dir';
  static const String keyThemeMode = 'theme_mode';
  static const String keyMergePreference = 'merge_preference';
  static const String keyFfmpegPath = 'ffmpeg_path';
  static const String keyBoardNick = 'board_nick';

  static const int defaultTaskConcurrency = 3;
  static const int defaultSegmentConcurrency = 8;

  Future<int> taskConcurrency() async {
    final v = await _db.settingValue(keyConcurrency);
    return int.tryParse(v ?? '') ?? defaultTaskConcurrency;
  }

  Future<void> setTaskConcurrency(int value) =>
      _db.setSetting(keyConcurrency, '$value');

  Future<int> segmentConcurrency() async {
    final v = await _db.settingValue(keySegmentConcurrency);
    return int.tryParse(v ?? '') ?? defaultSegmentConcurrency;
  }

  Future<void> setSegmentConcurrency(int value) =>
      _db.setSetting(keySegmentConcurrency, '$value');

  Future<String?> defaultSaveDir() => _db.settingValue(keyDefaultSaveDir);

  Future<void> setDefaultSaveDir(String path) =>
      _db.setSetting(keyDefaultSaveDir, path);

  /// Returns 'system', 'light' or 'dark'.
  Future<String> themeMode() async =>
      await _db.settingValue(keyThemeMode) ?? 'system';

  Future<void> setThemeMode(String mode) =>
      _db.setSetting(keyThemeMode, mode);

  /// Returns 'ts_only' or 'prefer_mp4'.
  Future<String> mergePreference() async =>
      await _db.settingValue(keyMergePreference) ?? 'prefer_mp4';

  Future<void> setMergePreference(String pref) =>
      _db.setSetting(keyMergePreference, pref);

  Future<String?> ffmpegPath() => _db.settingValue(keyFfmpegPath);

  Future<void> setFfmpegPath(String path) =>
      _db.setSetting(keyFfmpegPath, path);

  /// Nickname remembered between posts so guests do not retype it.
  Future<String?> boardNick() => _db.settingValue(keyBoardNick);

  Future<void> setBoardNick(String nick) =>
      _db.setSetting(keyBoardNick, nick);
}
