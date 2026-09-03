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
  /// **'Stream Mediary'**
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
