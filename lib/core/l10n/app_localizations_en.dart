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
  String get batchImport => 'Batch import';

  @override
  String get batchUrls => 'Playlist URLs, one per line';

  @override
  String get batchHint => 'Paste multiple http/https m3u8 URLs';

  @override
  String get batchReady => 'ready';

  @override
  String get batchAdd => 'Add to download queue';

  @override
  String get downloads => 'Downloads';

  @override
  String get history => 'History';

  @override
  String get searchHistory => 'Search downloaded videos';

  @override
  String get filterAll => 'All';

  @override
  String get filterIncomplete => 'Failed/Canceled';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortSize => 'Size';

  @override
  String get sortTitle => 'Title';

  @override
  String get fileMissing => 'Local file moved or deleted';

  @override
  String get rename => 'Rename';

  @override
  String continueAt(Object time) {
    return 'Continue · $time';
  }

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
  String get availableSpace => 'Available space';

  @override
  String get lowSpaceWarning =>
      'Storage may be insufficient; merging needs extra space.';

  @override
  String get recentSources => 'Recent sources';

  @override
  String get pasteClipboard => 'Paste URL from clipboard';

  @override
  String get downloadTitle => 'Video title';

  @override
  String get downloadTitleHint => 'Optional; generated from URL if empty';

  @override
  String get saveTemplate => 'Save header template';

  @override
  String get templateName => 'Template name';

  @override
  String get templatePrivacyHint =>
      'Headers, including cookies, are saved on this device. Save only values you want to keep; templates can be deleted.';

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
  String get replaceSource => 'Replace expired URL';

  @override
  String get invalidHeaderLine =>
      'Use one request header per line: Name: Value';

  @override
  String get copyDiagnostic => 'Copy diagnostics';

  @override
  String get diagnosticCopied => 'Redacted diagnostics copied';

  @override
  String get delete => 'Delete';

  @override
  String get play => 'Play';

  @override
  String get shareFile => 'Share file';

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
  String get queuePolicy => 'Download policy';

  @override
  String get sequentialQueue => 'Download tasks one at a time';

  @override
  String get wifiOnly => 'Wi-Fi / wired network only';

  @override
  String get chargingOnly => 'Only while charging';

  @override
  String get moveFirst => 'Prioritize';

  @override
  String get moveLast => 'Move to end';

  @override
  String get completionNotifications => 'Completion notifications';

  @override
  String get completionNotificationsHint =>
      'Send a system notification when a task completes';

  @override
  String get notificationPermissionDenied =>
      'Notification permission was not granted';

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
  String get errorAccessDenied =>
      'Access was denied or the link expired. Update the URL and request headers, then retry';

  @override
  String get errorMediaMissing =>
      'The video resource is missing or expired. Get a fresh playback URL';

  @override
  String get errorNetwork => 'Could not connect. Check your network and retry';

  @override
  String get errorServer => 'The video server is unavailable. Try again later';

  @override
  String get errorStorage =>
      'Cannot use the save folder. Check free space and folder permissions';

  @override
  String get errorLiveMedia => 'Recording live streams is not supported yet';

  @override
  String get errorProtectedMedia =>
      'This video uses an unsupported content protection method';

  @override
  String get errorUnsupportedMedia =>
      'This video stream format is not supported yet';

  @override
  String get errorInvalidMedia =>
      'No downloadable HLS video was found. Check the playback URL';

  @override
  String get errorTryAgain =>
      'The operation could not be completed. Try again later';

  @override
  String get errorCommunityUnavailable =>
      'The message board is unavailable. Try again later';

  @override
  String get errorMergeSegmentMissing =>
      'A segment needed for merging is missing. Download it again and retry';

  @override
  String get errorMergeFailed =>
      'Could not merge the video. Check the save folder and free space, then retry';

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
  String get navActive => 'In progress';

  @override
  String get newDownloadShort => 'New';

  @override
  String downloadsSummary(Object active, Object paused) {
    return '$active active · $paused paused';
  }

  @override
  String get downloadsSummaryEmpty => 'Everything is finished';

  @override
  String historySummary(Object count) {
    return '$count records';
  }

  @override
  String remaining(Object time) {
    return '$time left';
  }

  @override
  String segmentsProgress(Object done, Object total) {
    return '$done/$total segments';
  }

  @override
  String segmentsProgressLabel(Object percent, Object done, Object total) {
    return 'Progress $percent%, $done of $total segments downloaded';
  }

  @override
  String get pauseAll => 'Pause all';

  @override
  String get resumeAll => 'Resume all';

  @override
  String get mergeReadyHint =>
      'All segments downloaded, merging into a single file';

  @override
  String get estimatedSizeHint => 'Estimated for the selected quality';

  @override
  String get noSaveDir => 'No save directory set';

  @override
  String get urlSection => 'Playlist URL';

  @override
  String get previewSection => 'Parse result';

  @override
  String get advancedSection => 'Advanced options';

  @override
  String get advancedHint => 'Custom headers and decryption keys';

  @override
  String get headerSection => 'Custom headers';

  @override
  String get decryptSection => 'Decryption key override';

  @override
  String get decryptHint => 'Leave empty to use the keys from the playlist';

  @override
  String get startDownloadHint => 'Confirming adds this to the download queue';

  @override
  String get emptyDownloadsTitle => 'No downloads yet';

  @override
  String get emptyHistoryTitle => 'No history yet';

  @override
  String get emptyHistoryHint => 'Completed downloads appear here';

  @override
  String get emptyDownloadsAction => 'New download';

  @override
  String get liveBadge => 'Live stream';

  @override
  String get encryptedBadge => 'Encrypted';

  @override
  String get notEncryptedBadge => 'Not encrypted';

  @override
  String get mergeFolderSection => 'Segment folder';

  @override
  String get segmentsCountLabel => 'Segments';

  @override
  String get totalSizeLabel => 'Total size';

  @override
  String get fileRangeLabel => 'File range';

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

  @override
  String get navCommunity => 'Board';

  @override
  String get community => 'Message Board';

  @override
  String get communitySubtitle => 'Messages, feedback and discussion';

  @override
  String get communityNotConfigured => 'Message board server not configured';

  @override
  String get communityNotConfiguredHint =>
      'Set a Waline server URL in Settings to enable the board';

  @override
  String get communityNickHint => 'Nickname';

  @override
  String get communityContentHint => 'Say something…';

  @override
  String communityReplyTo(Object nick) {
    return 'Reply to @$nick';
  }

  @override
  String get communityPost => 'Post';

  @override
  String get communitySheetTitle => 'New message';

  @override
  String get communityReply => 'Reply';

  @override
  String get communityReplyAction => 'Reply';

  @override
  String communityExpandReplies(Object count) {
    return '$count replies';
  }

  @override
  String get communityCollapseReplies => 'Collapse';

  @override
  String get communityLoadMore => 'Load more';

  @override
  String get communityRefresh => 'Refresh';

  @override
  String get communityWarning =>
      'Please follow the law. Posting illegal or rule-breaking content is prohibited; violators bear full responsibility.';

  @override
  String communityPageInfo(Object page, Object total) {
    return 'Page $page of $total';
  }

  @override
  String get communityEmpty => 'No messages yet';

  @override
  String get communityEmptyHint => 'Be the first to post';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(Object count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count h ago';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count d ago';
  }
}
