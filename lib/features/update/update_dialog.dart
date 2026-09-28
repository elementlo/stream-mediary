import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/settings_repository.dart';
import '../../providers/app_providers.dart';
import 'update_service.dart';

enum _Phase { idle, downloading, installing, failed }

/// Shows the "new version available" dialog and drives download + install.
///
/// Closing the dialog cancels an in-flight download; the `.part` file is
/// kept so the next attempt resumes instead of restarting.
Future<void> showUpdateDialog(
  BuildContext context,
  UpdateInfo info, {
  bool rememberDismissed = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _UpdateDialog(
      info: info,
      rememberDismissed: rememberDismissed,
    ),
  );
}

class _UpdateDialog extends ConsumerStatefulWidget {
  const _UpdateDialog({required this.info, required this.rememberDismissed});

  final UpdateInfo info;
  final bool rememberDismissed;

  @override
  ConsumerState<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<_UpdateDialog> {
  _Phase _phase = _Phase.idle;
  int _received = 0;
  int _total = 0;
  String? _error;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel('dialog closed');
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (widget.rememberDismissed) {
      await ref
          .read(settingsRepositoryProvider)
          .setRaw(
            SettingsRepository.keyUpdatePromptedVersion,
            widget.info.version,
          );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _downloadAndInstall() async {
    final service = ref.read(updateServiceProvider);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _phase = _Phase.downloading;
      _error = null;
      _received = 0;
      _total = widget.info.assetSize;
    });
    _cancelToken = CancelToken();
    try {
      final root = await service.updatesDir();
      final destDir = Directory('${root.path}/${widget.info.version}');
      final file = await service.downloadUpdate(
        widget.info,
        destDir: destDir,
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _received = received;
              _total = total;
            });
          }
        },
      );
      if (!mounted) return;
      setState(() => _phase = _Phase.installing);
      await service.installUpdate(widget.info, file);
      if (!mounted) return;
      // Android/macOS return after handing off to the installer/Finder.
      Navigator.of(context).pop();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      _fail(l10n.updateDownloadFailed);
    } catch (_) {
      _fail(_errorText());
    }
  }

  String _errorText() {
    final l10n = AppLocalizations.of(context);
    return switch (_phase) {
      _Phase.installing => l10n.updateInstallFailed,
      _ => l10n.updateDownloadFailed,
    };
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.failed;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final info = widget.info;
    final downloading = _phase == _Phase.downloading;
    final busy = downloading || _phase == _Phase.installing;

    return AlertDialog(
      title: Text(l10n.updateAvailable(info.version)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.assetSize > 0 && !busy)
              Text(
                '${l10n.updateSize}: ${formatBytes(info.assetSize)}',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            if (Platform.isMacOS && !busy) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                l10n.updateMacHint,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: Spacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: info.body.isEmpty ? l10n.updateNoChangelog : info.body,
                  selectable: false,
                  styleSheet: MarkdownStyleSheet(
                    p: text.bodyMedium,
                    h1: text.titleMedium,
                    h2: text.titleSmall,
                    h3: text.titleSmall,
                    listBullet: text.bodyMedium,
                  ),
                ),
              ),
            ),
            if (busy) ...[
              const SizedBox(height: Spacing.lg),
              LinearProgressIndicator(
                value: downloading && _total > 0 ? _received / _total : null,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                _phase == _Phase.installing
                    ? l10n.updateInstalling
                    : _total > 0
                    ? '${formatBytes(_received)} / ${formatBytes(_total)}'
                    : formatBytes(_received),
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (_phase == _Phase.failed && _error != null) ...[
              const SizedBox(height: Spacing.lg),
              Text(
                _error!,
                style: text.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : _dismiss,
          child: Text(l10n.updateLater),
        ),
        if (_phase == _Phase.failed)
          FilledButton.icon(
            onPressed: _downloadAndInstall,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l10n.updateRetry),
          )
        else
          FilledButton.icon(
            onPressed: busy ? null : _downloadAndInstall,
            icon: downloading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, size: 16),
            label: Text(
              _phase == _Phase.installing
                  ? l10n.updateInstalling
                  : l10n.updateDownload,
            ),
          ),
      ],
    );
  }
}

/// Checks for an update and shows the dialog when one is available.
///
/// [manual] checks always report the outcome via SnackBar; automatic
/// (startup) checks stay silent and only prompt once per version.
Future<void> checkAndPromptUpdate(
  BuildContext context,
  WidgetRef ref, {
  required bool manual,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final service = ref.read(updateServiceProvider);
  final settings = ref.read(settingsRepositoryProvider);
  try {
    final info = await PackageInfo.fromPlatform();
    final update = await service.checkForUpdate(info.version);
    if (update == null) {
      if (manual) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.updateUpToDate)));
      }
      return;
    }
    if (!manual) {
      final prompted = await settings.raw(
        SettingsRepository.keyUpdatePromptedVersion,
      );
      if (prompted == update.version) return;
    }
    if (!context.mounted) return;
    await showUpdateDialog(context, update, rememberDismissed: !manual);
  } catch (_) {
    if (manual) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.updateCheckFailed)));
    }
  }
}
