// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Stream Mediary';

  @override
  String get navDownloads => '下载';

  @override
  String get navHistory => '历史';

  @override
  String get navSettings => '设置';

  @override
  String get newDownload => '新建下载';

  @override
  String get downloads => '下载中';

  @override
  String get history => '历史记录';

  @override
  String get settings => '设置';

  @override
  String get emptyDownloads => '暂无下载任务';

  @override
  String get emptyDownloadsHint => '点击下方按钮添加 m3u8 地址开始下载';

  @override
  String get emptyHistory => '暂无历史记录';

  @override
  String get m3u8UrlLabel => 'M3U8 地址';

  @override
  String get m3u8UrlHint => '请输入或粘贴 m3u8 播放列表地址';

  @override
  String get parse => '解析';

  @override
  String get parsing => '解析中…';

  @override
  String get advancedOptions => '高级选项';

  @override
  String get customHeaders => '自定义请求头';

  @override
  String get addHeader => '添加请求头';

  @override
  String get headerKey => '名称';

  @override
  String get headerValue => '值';

  @override
  String get customKey => '自定义 KEY (hex)';

  @override
  String get customIv => '自定义 IV (hex)';

  @override
  String get preview => '解析预览';

  @override
  String get segmentCount => '分片数量';

  @override
  String get totalDuration => '总时长';

  @override
  String get encrypted => '加密';

  @override
  String get notEncrypted => '未加密';

  @override
  String get estimatedSize => '估算大小';

  @override
  String get selectVariant => '选择清晰度';

  @override
  String get saveDirectory => '保存目录';

  @override
  String get chooseDirectory => '选择目录';

  @override
  String get startDownload => '开始下载';

  @override
  String get statusCreated => '已创建';

  @override
  String get statusParsing => '解析中';

  @override
  String get statusPreviewReady => '待确认';

  @override
  String get statusQueued => '排队中';

  @override
  String get statusDownloading => '下载中';

  @override
  String get statusPaused => '已暂停';

  @override
  String get statusMerging => '合并中';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusFailed => '失败';

  @override
  String get statusCanceled => '已取消';

  @override
  String get pause => '暂停';

  @override
  String get resume => '恢复';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重试';

  @override
  String get delete => '删除';

  @override
  String get play => '播放';

  @override
  String get redownload => '重新下载';

  @override
  String get openFolder => '打开所在目录';

  @override
  String get confirmCancelTitle => '取消下载';

  @override
  String get confirmCancelMessage => '确定要取消该下载任务吗？已下载的分片将被清理。';

  @override
  String get confirmDeleteTitle => '删除记录';

  @override
  String get confirmDeleteMessage => '确定要删除该历史记录吗？';

  @override
  String get confirm => '确定';

  @override
  String get concurrency => '任务并发数';

  @override
  String get defaultSaveDir => '默认保存目录';

  @override
  String get themeMode => '主题模式';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '亮色';

  @override
  String get themeDark => '暗色';

  @override
  String get mergePreference => '合并方式';

  @override
  String get mergeTsOnly => '仅 TS';

  @override
  String get mergePreferMp4 => '优先 MP4';

  @override
  String get ffmpegPath => 'ffmpeg 路径';

  @override
  String get ffmpegDetected => '已检测到 ffmpeg';

  @override
  String get ffmpegNotFound => '未检测到 ffmpeg';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get errorInvalidUrl => '请输入有效的地址';

  @override
  String errorParseFailed(Object message) {
    return '解析失败：$message';
  }

  @override
  String speed(Object speed) {
    return '$speed/s';
  }
}
