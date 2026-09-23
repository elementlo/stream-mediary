import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'Mediary'**
  String get appTitle;

  /// No description provided for @navDownloads.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get navDownloads;

  /// No description provided for @navHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @newDownload.
  ///
  /// In zh, this message translates to:
  /// **'新建下载'**
  String get newDownload;

  /// No description provided for @batchImport.
  ///
  /// In zh, this message translates to:
  /// **'批量导入'**
  String get batchImport;

  /// No description provided for @batchUrls.
  ///
  /// In zh, this message translates to:
  /// **'播放列表地址，每行一个'**
  String get batchUrls;

  /// No description provided for @batchHint.
  ///
  /// In zh, this message translates to:
  /// **'粘贴多个 http/https 的 m3u8 地址'**
  String get batchHint;

  /// No description provided for @batchReady.
  ///
  /// In zh, this message translates to:
  /// **'个可下载'**
  String get batchReady;

  /// No description provided for @batchAdd.
  ///
  /// In zh, this message translates to:
  /// **'加入下载队列'**
  String get batchAdd;

  /// No description provided for @downloads.
  ///
  /// In zh, this message translates to:
  /// **'下载中'**
  String get downloads;

  /// No description provided for @history.
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get history;

  /// No description provided for @searchHistory.
  ///
  /// In zh, this message translates to:
  /// **'搜索已下载内容'**
  String get searchHistory;

  /// No description provided for @filterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get filterAll;

  /// No description provided for @filterIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'失败/取消'**
  String get filterIncomplete;

  /// No description provided for @sortNewest.
  ///
  /// In zh, this message translates to:
  /// **'最新'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In zh, this message translates to:
  /// **'最早'**
  String get sortOldest;

  /// No description provided for @sortSize.
  ///
  /// In zh, this message translates to:
  /// **'按大小'**
  String get sortSize;

  /// No description provided for @sortTitle.
  ///
  /// In zh, this message translates to:
  /// **'按标题'**
  String get sortTitle;

  /// No description provided for @fileMissing.
  ///
  /// In zh, this message translates to:
  /// **'本地文件已移走或删除'**
  String get fileMissing;

  /// No description provided for @rename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get rename;

  /// No description provided for @continueAt.
  ///
  /// In zh, this message translates to:
  /// **'继续播放 · {time}'**
  String continueAt(Object time);

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @emptyDownloads.
  ///
  /// In zh, this message translates to:
  /// **'暂无下载任务'**
  String get emptyDownloads;

  /// No description provided for @emptyDownloadsHint.
  ///
  /// In zh, this message translates to:
  /// **'点击下方按钮添加 m3u8 地址开始下载'**
  String get emptyDownloadsHint;

  /// No description provided for @emptyHistory.
  ///
  /// In zh, this message translates to:
  /// **'暂无历史记录'**
  String get emptyHistory;

  /// No description provided for @m3u8UrlLabel.
  ///
  /// In zh, this message translates to:
  /// **'M3U8 地址'**
  String get m3u8UrlLabel;

  /// No description provided for @m3u8UrlHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入或粘贴 m3u8 播放列表地址'**
  String get m3u8UrlHint;

  /// No description provided for @parse.
  ///
  /// In zh, this message translates to:
  /// **'解析'**
  String get parse;

  /// No description provided for @parsing.
  ///
  /// In zh, this message translates to:
  /// **'解析中…'**
  String get parsing;

  /// No description provided for @advancedOptions.
  ///
  /// In zh, this message translates to:
  /// **'高级选项'**
  String get advancedOptions;

  /// No description provided for @customHeaders.
  ///
  /// In zh, this message translates to:
  /// **'自定义请求头'**
  String get customHeaders;

  /// No description provided for @addHeader.
  ///
  /// In zh, this message translates to:
  /// **'添加请求头'**
  String get addHeader;

  /// No description provided for @headerKey.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get headerKey;

  /// No description provided for @headerValue.
  ///
  /// In zh, this message translates to:
  /// **'值'**
  String get headerValue;

  /// No description provided for @customKey.
  ///
  /// In zh, this message translates to:
  /// **'自定义 KEY (hex)'**
  String get customKey;

  /// No description provided for @customIv.
  ///
  /// In zh, this message translates to:
  /// **'自定义 IV (hex)'**
  String get customIv;

  /// No description provided for @preview.
  ///
  /// In zh, this message translates to:
  /// **'解析预览'**
  String get preview;

  /// No description provided for @segmentCount.
  ///
  /// In zh, this message translates to:
  /// **'分片数量'**
  String get segmentCount;

  /// No description provided for @totalDuration.
  ///
  /// In zh, this message translates to:
  /// **'总时长'**
  String get totalDuration;

  /// No description provided for @encrypted.
  ///
  /// In zh, this message translates to:
  /// **'加密'**
  String get encrypted;

  /// No description provided for @notEncrypted.
  ///
  /// In zh, this message translates to:
  /// **'未加密'**
  String get notEncrypted;

  /// No description provided for @estimatedSize.
  ///
  /// In zh, this message translates to:
  /// **'估算大小'**
  String get estimatedSize;

  /// No description provided for @availableSpace.
  ///
  /// In zh, this message translates to:
  /// **'可用空间'**
  String get availableSpace;

  /// No description provided for @lowSpaceWarning.
  ///
  /// In zh, this message translates to:
  /// **'可用空间可能不足；合并时还需要额外空间。'**
  String get lowSpaceWarning;

  /// No description provided for @recentSources.
  ///
  /// In zh, this message translates to:
  /// **'最近来源'**
  String get recentSources;

  /// No description provided for @pasteClipboard.
  ///
  /// In zh, this message translates to:
  /// **'粘贴剪贴板链接'**
  String get pasteClipboard;

  /// No description provided for @downloadTitle.
  ///
  /// In zh, this message translates to:
  /// **'视频标题'**
  String get downloadTitle;

  /// No description provided for @downloadTitleHint.
  ///
  /// In zh, this message translates to:
  /// **'可选，留空则从地址生成'**
  String get downloadTitleHint;

  /// No description provided for @saveTemplate.
  ///
  /// In zh, this message translates to:
  /// **'保存请求头模板'**
  String get saveTemplate;

  /// No description provided for @templateName.
  ///
  /// In zh, this message translates to:
  /// **'模板名称'**
  String get templateName;

  /// No description provided for @templatePrivacyHint.
  ///
  /// In zh, this message translates to:
  /// **'请求头（包括 Cookie）将保存在本机。只保存你愿意保留的值，可随时删除模板。'**
  String get templatePrivacyHint;

  /// No description provided for @selectVariant.
  ///
  /// In zh, this message translates to:
  /// **'选择清晰度'**
  String get selectVariant;

  /// No description provided for @saveDirectory.
  ///
  /// In zh, this message translates to:
  /// **'保存目录'**
  String get saveDirectory;

  /// No description provided for @chooseDirectory.
  ///
  /// In zh, this message translates to:
  /// **'选择目录'**
  String get chooseDirectory;

  /// No description provided for @startDownload.
  ///
  /// In zh, this message translates to:
  /// **'开始下载'**
  String get startDownload;

  /// No description provided for @statusCreated.
  ///
  /// In zh, this message translates to:
  /// **'已创建'**
  String get statusCreated;

  /// No description provided for @statusParsing.
  ///
  /// In zh, this message translates to:
  /// **'解析中'**
  String get statusParsing;

  /// No description provided for @statusPreviewReady.
  ///
  /// In zh, this message translates to:
  /// **'待确认'**
  String get statusPreviewReady;

  /// No description provided for @statusQueued.
  ///
  /// In zh, this message translates to:
  /// **'排队中'**
  String get statusQueued;

  /// No description provided for @statusDownloading.
  ///
  /// In zh, this message translates to:
  /// **'下载中'**
  String get statusDownloading;

  /// No description provided for @statusPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get statusPaused;

  /// No description provided for @statusMerging.
  ///
  /// In zh, this message translates to:
  /// **'合并中'**
  String get statusMerging;

  /// No description provided for @statusCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get statusFailed;

  /// No description provided for @statusCanceled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get statusCanceled;

  /// No description provided for @pause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get resume;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @replaceSource.
  ///
  /// In zh, this message translates to:
  /// **'更新失效链接'**
  String get replaceSource;

  /// No description provided for @invalidHeaderLine.
  ///
  /// In zh, this message translates to:
  /// **'请求头格式应为「名称: 值」，每行一项'**
  String get invalidHeaderLine;

  /// No description provided for @copyDiagnostic.
  ///
  /// In zh, this message translates to:
  /// **'复制诊断'**
  String get copyDiagnostic;

  /// No description provided for @diagnosticCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制脱敏诊断信息'**
  String get diagnosticCopied;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @play.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get play;

  /// No description provided for @shareFile.
  ///
  /// In zh, this message translates to:
  /// **'分享文件'**
  String get shareFile;

  /// No description provided for @redownload.
  ///
  /// In zh, this message translates to:
  /// **'重新下载'**
  String get redownload;

  /// No description provided for @openFolder.
  ///
  /// In zh, this message translates to:
  /// **'打开所在目录'**
  String get openFolder;

  /// No description provided for @confirmCancelTitle.
  ///
  /// In zh, this message translates to:
  /// **'取消下载'**
  String get confirmCancelTitle;

  /// No description provided for @confirmCancelMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要取消该下载任务吗？已下载的分片将被清理。'**
  String get confirmCancelMessage;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除记录'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除该历史记录吗？'**
  String get confirmDeleteMessage;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @concurrency.
  ///
  /// In zh, this message translates to:
  /// **'任务并发数'**
  String get concurrency;

  /// No description provided for @queuePolicy.
  ///
  /// In zh, this message translates to:
  /// **'下载策略'**
  String get queuePolicy;

  /// No description provided for @sequentialQueue.
  ///
  /// In zh, this message translates to:
  /// **'逐个下载任务'**
  String get sequentialQueue;

  /// No description provided for @wifiOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅 Wi-Fi / 有线网络下载'**
  String get wifiOnly;

  /// No description provided for @chargingOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅充电时下载'**
  String get chargingOnly;

  /// No description provided for @moveFirst.
  ///
  /// In zh, this message translates to:
  /// **'优先下载'**
  String get moveFirst;

  /// No description provided for @moveLast.
  ///
  /// In zh, this message translates to:
  /// **'移到末尾'**
  String get moveLast;

  /// No description provided for @completionNotifications.
  ///
  /// In zh, this message translates to:
  /// **'完成通知'**
  String get completionNotifications;

  /// No description provided for @completionNotificationsHint.
  ///
  /// In zh, this message translates to:
  /// **'任务完成时发送系统通知'**
  String get completionNotificationsHint;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'系统未授予通知权限'**
  String get notificationPermissionDenied;

  /// No description provided for @defaultSaveDir.
  ///
  /// In zh, this message translates to:
  /// **'默认保存目录'**
  String get defaultSaveDir;

  /// No description provided for @themeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'亮色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'暗色'**
  String get themeDark;

  /// No description provided for @mergePreference.
  ///
  /// In zh, this message translates to:
  /// **'合并方式'**
  String get mergePreference;

  /// No description provided for @mergeTsOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅 TS'**
  String get mergeTsOnly;

  /// No description provided for @mergePreferMp4.
  ///
  /// In zh, this message translates to:
  /// **'优先 MP4'**
  String get mergePreferMp4;

  /// No description provided for @ffmpegPath.
  ///
  /// In zh, this message translates to:
  /// **'ffmpeg 路径'**
  String get ffmpegPath;

  /// No description provided for @ffmpegDetected.
  ///
  /// In zh, this message translates to:
  /// **'已检测到 ffmpeg'**
  String get ffmpegDetected;

  /// No description provided for @ffmpegNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未检测到 ffmpeg'**
  String get ffmpegNotFound;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get version;

  /// No description provided for @errorInvalidUrl.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的地址'**
  String get errorInvalidUrl;

  /// No description provided for @errorParseFailed.
  ///
  /// In zh, this message translates to:
  /// **'解析失败：{message}'**
  String errorParseFailed(Object message);

  /// No description provided for @speed.
  ///
  /// In zh, this message translates to:
  /// **'{speed}/s'**
  String speed(Object speed);

  /// No description provided for @storagePermissionHint.
  ///
  /// In zh, this message translates to:
  /// **'需在系统设置中授予「所有文件访问」权限，才能保存到所选目录'**
  String get storagePermissionHint;

  /// No description provided for @storagePermissionGranted.
  ///
  /// In zh, this message translates to:
  /// **'已获取存储权限'**
  String get storagePermissionGranted;

  /// No description provided for @playerNoOutput.
  ///
  /// In zh, this message translates to:
  /// **'该任务没有可播放的输出文件'**
  String get playerNoOutput;

  /// No description provided for @playerFileMissing.
  ///
  /// In zh, this message translates to:
  /// **'输出文件不存在，可能已被删除'**
  String get playerFileMissing;

  /// No description provided for @playerOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法播放该文件（格式不受支持或已损坏）'**
  String get playerOpenFailed;

  /// No description provided for @navMerge.
  ///
  /// In zh, this message translates to:
  /// **'合并'**
  String get navMerge;

  /// No description provided for @navActive.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get navActive;

  /// No description provided for @newDownloadShort.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get newDownloadShort;

  /// No description provided for @downloadsSummary.
  ///
  /// In zh, this message translates to:
  /// **'{active} 个进行中 · {paused} 个已暂停'**
  String downloadsSummary(Object active, Object paused);

  /// No description provided for @downloadsSummaryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'所有任务都已完成'**
  String get downloadsSummaryEmpty;

  /// No description provided for @historySummary.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条记录'**
  String historySummary(Object count);

  /// No description provided for @remaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {time}'**
  String remaining(Object time);

  /// No description provided for @segmentsProgress.
  ///
  /// In zh, this message translates to:
  /// **'{done}/{total} 分片'**
  String segmentsProgress(Object done, Object total);

  /// No description provided for @segmentsProgressLabel.
  ///
  /// In zh, this message translates to:
  /// **'进度 {percent}%，已下载 {done}/{total} 个分片'**
  String segmentsProgressLabel(Object percent, Object done, Object total);

  /// No description provided for @pauseAll.
  ///
  /// In zh, this message translates to:
  /// **'全部暂停'**
  String get pauseAll;

  /// No description provided for @resumeAll.
  ///
  /// In zh, this message translates to:
  /// **'全部恢复'**
  String get resumeAll;

  /// No description provided for @mergeReadyHint.
  ///
  /// In zh, this message translates to:
  /// **'分片已全部下载，正在合并为单个文件'**
  String get mergeReadyHint;

  /// No description provided for @estimatedSizeHint.
  ///
  /// In zh, this message translates to:
  /// **'按所选清晰度估算'**
  String get estimatedSizeHint;

  /// No description provided for @noSaveDir.
  ///
  /// In zh, this message translates to:
  /// **'未设置保存目录'**
  String get noSaveDir;

  /// No description provided for @urlSection.
  ///
  /// In zh, this message translates to:
  /// **'播放列表地址'**
  String get urlSection;

  /// No description provided for @previewSection.
  ///
  /// In zh, this message translates to:
  /// **'解析结果'**
  String get previewSection;

  /// No description provided for @advancedSection.
  ///
  /// In zh, this message translates to:
  /// **'高级选项'**
  String get advancedSection;

  /// No description provided for @advancedHint.
  ///
  /// In zh, this message translates to:
  /// **'自定义请求头与解密密钥'**
  String get advancedHint;

  /// No description provided for @headerSection.
  ///
  /// In zh, this message translates to:
  /// **'自定义请求头'**
  String get headerSection;

  /// No description provided for @decryptSection.
  ///
  /// In zh, this message translates to:
  /// **'解密密钥覆盖'**
  String get decryptSection;

  /// No description provided for @decryptHint.
  ///
  /// In zh, this message translates to:
  /// **'留空则使用播放列表中的密钥'**
  String get decryptHint;

  /// No description provided for @startDownloadHint.
  ///
  /// In zh, this message translates to:
  /// **'确认后将加入下载队列'**
  String get startDownloadHint;

  /// No description provided for @emptyDownloadsTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无下载任务'**
  String get emptyDownloadsTitle;

  /// No description provided for @emptyHistoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无历史记录'**
  String get emptyHistoryTitle;

  /// No description provided for @emptyHistoryHint.
  ///
  /// In zh, this message translates to:
  /// **'完成的下载会出现在这里'**
  String get emptyHistoryHint;

  /// No description provided for @emptyDownloadsAction.
  ///
  /// In zh, this message translates to:
  /// **'新建下载'**
  String get emptyDownloadsAction;

  /// No description provided for @liveBadge.
  ///
  /// In zh, this message translates to:
  /// **'直播流'**
  String get liveBadge;

  /// No description provided for @encryptedBadge.
  ///
  /// In zh, this message translates to:
  /// **'加密'**
  String get encryptedBadge;

  /// No description provided for @notEncryptedBadge.
  ///
  /// In zh, this message translates to:
  /// **'未加密'**
  String get notEncryptedBadge;

  /// No description provided for @mergeFolderSection.
  ///
  /// In zh, this message translates to:
  /// **'切片文件夹'**
  String get mergeFolderSection;

  /// No description provided for @segmentsCountLabel.
  ///
  /// In zh, this message translates to:
  /// **'切片数量'**
  String get segmentsCountLabel;

  /// No description provided for @totalSizeLabel.
  ///
  /// In zh, this message translates to:
  /// **'总大小'**
  String get totalSizeLabel;

  /// No description provided for @fileRangeLabel.
  ///
  /// In zh, this message translates to:
  /// **'文件范围'**
  String get fileRangeLabel;

  /// No description provided for @mergeChooseFolder.
  ///
  /// In zh, this message translates to:
  /// **'选择文件夹'**
  String get mergeChooseFolder;

  /// No description provided for @mergePreview.
  ///
  /// In zh, this message translates to:
  /// **'扫描结果'**
  String get mergePreview;

  /// No description provided for @mergeSegmentsFound.
  ///
  /// In zh, this message translates to:
  /// **'发现 {count} 个切片'**
  String mergeSegmentsFound(Object count);

  /// No description provided for @mergeTotalSize.
  ///
  /// In zh, this message translates to:
  /// **'总大小：{size}'**
  String mergeTotalSize(Object size);

  /// No description provided for @mergeStart.
  ///
  /// In zh, this message translates to:
  /// **'开始合并'**
  String get mergeStart;

  /// No description provided for @mergeInProgress.
  ///
  /// In zh, this message translates to:
  /// **'合并中…'**
  String get mergeInProgress;

  /// No description provided for @mergeRemuxing.
  ///
  /// In zh, this message translates to:
  /// **'正在转换为 MP4…'**
  String get mergeRemuxing;

  /// No description provided for @mergeSuccess.
  ///
  /// In zh, this message translates to:
  /// **'合并成功：{path}'**
  String mergeSuccess(Object path);

  /// No description provided for @mergeFailed.
  ///
  /// In zh, this message translates to:
  /// **'合并失败：{message}'**
  String mergeFailed(Object message);

  /// No description provided for @mergeNoTsFiles.
  ///
  /// In zh, this message translates to:
  /// **'该文件夹下没有找到 .ts 切片文件'**
  String get mergeNoTsFiles;

  /// No description provided for @mergeFolderUnreadable.
  ///
  /// In zh, this message translates to:
  /// **'无法读取该文件夹'**
  String get mergeFolderUnreadable;

  /// No description provided for @mergeSegmentMissing.
  ///
  /// In zh, this message translates to:
  /// **'切片文件缺失：{path}'**
  String mergeSegmentMissing(Object path);

  /// No description provided for @mergeMobileTsHint.
  ///
  /// In zh, this message translates to:
  /// **'移动端暂不支持转 MP4，已输出 TS 文件'**
  String get mergeMobileTsHint;

  /// No description provided for @mergeRemuxFailedHint.
  ///
  /// In zh, this message translates to:
  /// **'未检测到 ffmpeg 或转换失败，已保留 TS 文件'**
  String get mergeRemuxFailedHint;

  /// No description provided for @mergeOpenOutput.
  ///
  /// In zh, this message translates to:
  /// **'打开文件'**
  String get mergeOpenOutput;

  /// No description provided for @deleteLocalFiles.
  ///
  /// In zh, this message translates to:
  /// **'同时删除本地文件'**
  String get deleteLocalFiles;

  /// No description provided for @clearCompleted.
  ///
  /// In zh, this message translates to:
  /// **'清除已完成'**
  String get clearCompleted;

  /// No description provided for @confirmClearCompletedTitle.
  ///
  /// In zh, this message translates to:
  /// **'清除已完成任务'**
  String get confirmClearCompletedTitle;

  /// No description provided for @confirmClearCompletedMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有已完成的下载记录吗？'**
  String get confirmClearCompletedMessage;

  /// No description provided for @clearedCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已清除 {count} 条已完成记录'**
  String clearedCompleted(Object count);

  /// No description provided for @navCommunity.
  ///
  /// In zh, this message translates to:
  /// **'留言板'**
  String get navCommunity;

  /// No description provided for @community.
  ///
  /// In zh, this message translates to:
  /// **'留言板'**
  String get community;

  /// No description provided for @communitySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'留言、反馈与使用交流'**
  String get communitySubtitle;

  /// No description provided for @communityNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置留言板服务'**
  String get communityNotConfigured;

  /// No description provided for @communityNotConfiguredHint.
  ///
  /// In zh, this message translates to:
  /// **'在设置中填写 Waline 服务地址后即可使用'**
  String get communityNotConfiguredHint;

  /// No description provided for @communityNickHint.
  ///
  /// In zh, this message translates to:
  /// **'昵称'**
  String get communityNickHint;

  /// No description provided for @communityContentHint.
  ///
  /// In zh, this message translates to:
  /// **'说点什么…'**
  String get communityContentHint;

  /// No description provided for @communityReplyTo.
  ///
  /// In zh, this message translates to:
  /// **'回复 @{nick}'**
  String communityReplyTo(Object nick);

  /// No description provided for @communityPost.
  ///
  /// In zh, this message translates to:
  /// **'发布'**
  String get communityPost;

  /// No description provided for @communitySheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'发布留言'**
  String get communitySheetTitle;

  /// No description provided for @communityReply.
  ///
  /// In zh, this message translates to:
  /// **'回复'**
  String get communityReply;

  /// No description provided for @communityReplyAction.
  ///
  /// In zh, this message translates to:
  /// **'回复'**
  String get communityReplyAction;

  /// No description provided for @communityExpandReplies.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条回复'**
  String communityExpandReplies(Object count);

  /// No description provided for @communityCollapseReplies.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get communityCollapseReplies;

  /// No description provided for @communityLoadMore.
  ///
  /// In zh, this message translates to:
  /// **'加载更多'**
  String get communityLoadMore;

  /// No description provided for @communityRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get communityRefresh;

  /// No description provided for @communityWarning.
  ///
  /// In zh, this message translates to:
  /// **'请遵守法律法规，严禁发布违规违法内容，违者需自行承担相应责任。'**
  String get communityWarning;

  /// No description provided for @communityPageInfo.
  ///
  /// In zh, this message translates to:
  /// **'第 {page} / {total} 页'**
  String communityPageInfo(Object page, Object total);

  /// No description provided for @communityEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有留言'**
  String get communityEmpty;

  /// No description provided for @communityEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'来发布第一条留言吧'**
  String get communityEmptyHint;

  /// No description provided for @timeJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分钟前'**
  String timeMinutesAgo(Object count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小时前'**
  String timeHoursAgo(Object count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天前'**
  String timeDaysAgo(Object count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
