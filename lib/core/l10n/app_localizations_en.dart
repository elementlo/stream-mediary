// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mediary';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get newDownload => 'New Download';

  @override
  String get downloads => 'Downloads';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get emptyDownloads => 'No downloads yet';

  @override
  String get emptyDownloadsHint =>
      'Tap the button below to add an m3u8 URL and start downloading';

  @override
  String get emptyHistory => 'No history yet';

  @override
  String get m3u8UrlLabel => 'M3U8 URL';

  @override
  String get m3u8UrlHint => 'Enter or paste an m3u8 playlist URL';

  @override
  String get parse => 'Parse';

  @override
  String get parsing => 'Parsing…';

  @override
  String get advancedOptions => 'Advanced options';

  @override
  String get customHeaders => 'Custom headers';

  @override
  String get addHeader => 'Add header';

  @override
  String get headerKey => 'Name';

  @override
  String get headerValue => 'Value';

  @override
  String get customKey => 'Custom KEY (hex)';

  @override
  String get customIv => 'Custom IV (hex)';

  @override
  String get preview => 'Preview';

  @override
  String get segmentCount => 'Segments';

  @override
  String get totalDuration => 'Duration';

  @override
  String get encrypted => 'Encrypted';

  @override
  String get notEncrypted => 'Not encrypted';

  @override
  String get estimatedSize => 'Estimated size';

  @override
  String get selectVariant => 'Select quality';

  @override
  String get saveDirectory => 'Save directory';

  @override
  String get chooseDirectory => 'Choose directory';

  @override
  String get startDownload => 'Start download';

  @override
  String get statusCreated => 'Created';

  @override
  String get statusParsing => 'Parsing';

  @override
  String get statusPreviewReady => 'Awaiting confirm';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusDownloading => 'Downloading';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusMerging => 'Merging';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get delete => 'Delete';

  @override
  String get play => 'Play';

  @override
  String get redownload => 'Download again';

  @override
  String get openFolder => 'Open folder';

  @override
  String get confirmCancelTitle => 'Cancel download';

  @override
  String get confirmCancelMessage =>
      'Cancel this download? Downloaded segments will be cleaned up.';

  @override
  String get confirmDeleteTitle => 'Delete record';

  @override
  String get confirmDeleteMessage => 'Delete this history record?';

  @override
  String get confirm => 'Confirm';

  @override
  String get concurrency => 'Task concurrency';

  @override
  String get defaultSaveDir => 'Default save directory';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get mergePreference => 'Merge mode';

  @override
  String get mergeTsOnly => 'TS only';

  @override
  String get mergePreferMp4 => 'Prefer MP4';

  @override
  String get ffmpegPath => 'ffmpeg path';

  @override
  String get ffmpegDetected => 'ffmpeg detected';

  @override
  String get ffmpegNotFound => 'ffmpeg not found';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get errorInvalidUrl => 'Please enter a valid URL';

  @override
  String errorParseFailed(Object message) {
    return 'Parse failed: $message';
  }

  @override
  String speed(Object speed) {
    return '$speed/s';
  }

  @override
  String get storagePermissionHint =>
      'Grant \"All files access\" in system settings to save into the chosen folder';

  @override
  String get storagePermissionGranted => 'Storage permission granted';

  @override
  String get playerNoOutput => 'This task has no playable output file';

  @override
  String get playerFileMissing =>
      'The output file does not exist; it may have been deleted';

  @override
  String get playerOpenFailed =>
      'Cannot play this file (unsupported format or corrupted)';

  @override
  String get navMerge => 'Merge';

  @override
  String get mergeFolderSection => 'Segment folder';

  @override
  String get mergeChooseFolder => 'Choose folder';

  @override
  String get mergePreview => 'Scan result';

  @override
  String mergeSegmentsFound(Object count) {
    return 'Found $count segments';
  }

  @override
  String mergeTotalSize(Object size) {
    return 'Total size: $size';
  }

  @override
  String get mergeStart => 'Start merge';

  @override
  String get mergeInProgress => 'Merging…';

  @override
  String get mergeRemuxing => 'Converting to MP4…';

  @override
  String mergeSuccess(Object path) {
    return 'Merge complete: $path';
  }

  @override
  String mergeFailed(Object message) {
    return 'Merge failed: $message';
  }

  @override
  String get mergeNoTsFiles => 'No .ts segment files found in this folder';

  @override
  String get mergeFolderUnreadable => 'Cannot read this folder';

  @override
  String mergeSegmentMissing(Object path) {
    return 'Segment file missing: $path';
  }

  @override
  String get mergeMobileTsHint =>
      'MP4 conversion is not supported on mobile; a TS file was output';

  @override
  String get mergeRemuxFailedHint =>
      'ffmpeg not found or conversion failed; the TS file was kept';

  @override
  String get mergeOpenOutput => 'Open file';

  @override
  String get deleteLocalFiles => 'Also delete local files';

  @override
  String get clearCompleted => 'Clear completed';

  @override
  String get confirmClearCompletedTitle => 'Clear completed tasks';

  @override
  String get confirmClearCompletedMessage =>
      'Remove all completed download records?';

  @override
  String clearedCompleted(Object count) {
    return 'Cleared $count completed records';
  }
}
