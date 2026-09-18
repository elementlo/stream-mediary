// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Mediary';

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

  @override
  String get storagePermissionHint => '需在系统设置中授予「所有文件访问」权限，才能保存到所选目录';

  @override
  String get storagePermissionGranted => '已获取存储权限';

  @override
  String get playerNoOutput => '该任务没有可播放的输出文件';

  @override
  String get playerFileMissing => '输出文件不存在，可能已被删除';

  @override
  String get playerOpenFailed => '无法播放该文件（格式不受支持或已损坏）';

  @override
  String get navMerge => '合并';

  @override
  String get navActive => '进行中';

  @override
  String get newDownloadShort => '新建';

  @override
  String downloadsSummary(Object active, Object paused) {
    return '$active 个进行中 · $paused 个已暂停';
  }

  @override
  String get downloadsSummaryEmpty => '所有任务都已完成';

  @override
  String historySummary(Object count) {
    return '$count 条记录';
  }

  @override
  String remaining(Object time) {
    return '剩余 $time';
  }

  @override
  String segmentsProgress(Object done, Object total) {
    return '$done/$total 分片';
  }

  @override
  String segmentsProgressLabel(Object percent, Object done, Object total) {
    return '进度 $percent%，已下载 $done/$total 个分片';
  }

  @override
  String get pauseAll => '全部暂停';

  @override
  String get resumeAll => '全部恢复';

  @override
  String get mergeReadyHint => '分片已全部下载，正在合并为单个文件';

  @override
  String get estimatedSizeHint => '按所选清晰度估算';

  @override
  String get noSaveDir => '未设置保存目录';

  @override
  String get urlSection => '播放列表地址';

  @override
  String get previewSection => '解析结果';

  @override
  String get advancedSection => '高级选项';

  @override
  String get advancedHint => '自定义请求头与解密密钥';

  @override
  String get headerSection => '自定义请求头';

  @override
  String get decryptSection => '解密密钥覆盖';

  @override
  String get decryptHint => '留空则使用播放列表中的密钥';

  @override
  String get startDownloadHint => '确认后将加入下载队列';

  @override
  String get emptyDownloadsTitle => '暂无下载任务';

  @override
  String get emptyHistoryTitle => '暂无历史记录';

  @override
  String get emptyHistoryHint => '完成的下载会出现在这里';

  @override
  String get emptyDownloadsAction => '新建下载';

  @override
  String get liveBadge => '直播流';

  @override
  String get encryptedBadge => '加密';

  @override
  String get notEncryptedBadge => '未加密';

  @override
  String get mergeFolderSection => '切片文件夹';

  @override
  String get segmentsCountLabel => '切片数量';

  @override
  String get totalSizeLabel => '总大小';

  @override
  String get fileRangeLabel => '文件范围';

  @override
  String get mergeChooseFolder => '选择文件夹';

  @override
  String get mergePreview => '扫描结果';

  @override
  String mergeSegmentsFound(Object count) {
    return '发现 $count 个切片';
  }

  @override
  String mergeTotalSize(Object size) {
    return '总大小：$size';
  }

  @override
  String get mergeStart => '开始合并';

  @override
  String get mergeInProgress => '合并中…';

  @override
  String get mergeRemuxing => '正在转换为 MP4…';

  @override
  String mergeSuccess(Object path) {
    return '合并成功：$path';
  }

  @override
  String mergeFailed(Object message) {
    return '合并失败：$message';
  }

  @override
  String get mergeNoTsFiles => '该文件夹下没有找到 .ts 切片文件';

  @override
  String get mergeFolderUnreadable => '无法读取该文件夹';

  @override
  String mergeSegmentMissing(Object path) {
    return '切片文件缺失：$path';
  }

  @override
  String get mergeMobileTsHint => '移动端暂不支持转 MP4，已输出 TS 文件';

  @override
  String get mergeRemuxFailedHint => '未检测到 ffmpeg 或转换失败，已保留 TS 文件';

  @override
  String get mergeOpenOutput => '打开文件';

  @override
  String get deleteLocalFiles => '同时删除本地文件';

  @override
  String get clearCompleted => '清除已完成';

  @override
  String get confirmClearCompletedTitle => '清除已完成任务';

  @override
  String get confirmClearCompletedMessage => '确定要清除所有已完成的下载记录吗？';

  @override
  String clearedCompleted(Object count) {
    return '已清除 $count 条已完成记录';
  }
}
