/// Explanations deliberately omit request headers, query strings and keys.
class FailureDiagnosis {
  const FailureDiagnosis(this.reason, this.action, this.code);
  final String reason;
  final String action;
  final String code;

  static FailureDiagnosis fromError(String? error) {
    final value = (error ?? '').toLowerCase();
    if (value.contains('403') || value.contains('401')) {
      return const FailureDiagnosis(
        '访问被拒绝或链接已过期',
        '更新播放列表地址及所需请求头后重试',
        'http_auth',
      );
    }
    if (value.contains('404') || value.contains('410')) {
      return const FailureDiagnosis(
        '媒体分片已失效',
        '获取新的播放列表地址后恢复任务',
        'missing_media',
      );
    }
    if (value.contains('space') || value.contains('errno = 28')) {
      return const FailureDiagnosis('设备存储空间不足', '清理空间或改用其他保存目录', 'no_space');
    }
    if (value.contains('timeout') ||
        value.contains('connection') ||
        value.contains('socket')) {
      return const FailureDiagnosis('网络连接中断或超时', '检查网络后重试任务', 'network');
    }
    if (value.contains('initialization') ||
        value.contains('byte range') ||
        value.contains('unsupported')) {
      return const FailureDiagnosis('此媒体流结构暂不受支持', '检查原地址或反馈脱敏诊断信息', 'format');
    }
    if (value.contains('merge') || value.contains('ffmpeg')) {
      return const FailureDiagnosis('媒体合并失败', '确认磁盘空间后重试或选择仅 TS', 'merge');
    }
    return const FailureDiagnosis('下载未能完成', '重试；若重复失败，请复制诊断信息反馈', 'other');
  }

  String report({required String taskId, required String url}) {
    final uri = Uri.tryParse(url);
    return 'Mediary diagnostic\nTask: $taskId\nHost: ${uri?.host ?? 'unknown'}\n'
        'Code: $code\nReason: $reason';
  }
}
