import 'package:flutter/material.dart';
import 'package:disk_usage/disk_usage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/mediary_scaffold.dart';
import '../../engine/engine_config.dart';
import '../../engine/m3u8/playlist.dart';
import '../../providers/app_providers.dart';
import '../../data/repositories/source_repository.dart';

class BatchDownloadPage extends ConsumerStatefulWidget {
  const BatchDownloadPage({super.key});
  @override
  ConsumerState<BatchDownloadPage> createState() => _BatchDownloadPageState();
}

class _BatchItem {
  _BatchItem(this.sourceUrl);
  final String sourceUrl;
  String? mediaUrl;
  MediaPlaylist? playlist;
  int? estimatedBytes;
  String? error;
  bool added = false;
}

class _BatchDownloadPageState extends ConsumerState<BatchDownloadPage> {
  final _controller = TextEditingController();
  List<_BatchItem> _items = [];
  bool _busy = false;
  List<SourceTemplate> _templates = [];
  String? _templateName;
  int? _availableBytes;

  Map<String, String> get _headers {
    for (final template in _templates) {
      if (template.name == _templateName) return template.headers;
    }
    return const {};
  }

  @override
  void initState() {
    super.initState();
    ref.read(sourceRepositoryProvider).templates().then((templates) {
      if (mounted) setState(() => _templates = templates);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    final urls = _controller.text
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    setState(() {
      _busy = true;
      _items = urls.map(_BatchItem.new).toList();
    });
    final engine = ref.read(downloadEngineProvider);
    final headers = _headers;
    try {
      _availableBytes = await DiskUsage.freeSpace(
        await ref.read(defaultSaveDirProvider.future),
      );
    } catch (_) {
      _availableBytes = null;
    }
    for (final item in _items) {
      try {
        final result = await engine.parseForPreview(
          item.sourceUrl,
          headers: headers,
        );
        if (result is MasterParseResult) {
          item.mediaUrl = result.master.variants.first.url;
          final child = await engine.parseForPreview(
            item.mediaUrl!,
            headers: headers,
          );
          if (child is! MediaParseResult) {
            throw StateError('Variant is not media');
          }
          item.playlist = child.media;
          item.estimatedBytes =
              (result.master.variants.first.bandwidth ?? 0) > 0
              ? (result.master.variants.first.bandwidth! *
                        child.media.totalDuration /
                        8)
                    .round()
              : await engine.estimateMediaBytes(child.media, headers: headers);
        } else {
          item.mediaUrl = item.sourceUrl;
          item.playlist = (result as MediaParseResult).media;
          item.estimatedBytes = await engine.estimateMediaBytes(
            item.playlist!,
            headers: headers,
          );
        }
        if (item.playlist!.isLive) {
          throw StateError('Live recording is not supported');
        }
      } catch (error) {
        item.error = '$error';
        item.playlist = null;
        item.estimatedBytes = null;
      }
      if (mounted) setState(() {});
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _addAll() async {
    setState(() => _busy = true);
    final engine = ref.read(downloadEngineProvider);
    for (final item in _items.where(
      (item) => item.playlist != null && !item.added,
    )) {
      try {
        await engine.startTask(
          id: const Uuid().v4(),
          request: DownloadRequest(
            url: item.mediaUrl!,
            sourceUrl: item.sourceUrl,
            headers: _headers,
          ),
          playlist: item.playlist!,
        );
        await ref.read(sourceRepositoryProvider).remember(item.sourceUrl);
        item.added = true;
      } catch (error) {
        item.error = '$error';
      }
      if (mounted) setState(() {});
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (_items.every((item) => item.added || item.playlist == null)) {
      context.go('/downloads');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ready = _items
        .where((item) => item.playlist != null && !item.added)
        .toList();
    final estimated = ready.every((item) => item.estimatedBytes != null)
        ? ready.fold<int>(0, (sum, item) => sum + item.estimatedBytes!)
        : null;
    return MediaryScaffold(
      title: l10n.batchImport,
      maxWidth: Breakpoints.contentForm,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.pop(),
      ),
      child: ListView(
        children: [
          TextField(
            controller: _controller,
            minLines: 6,
            maxLines: 12,
            decoration: InputDecoration(
              labelText: l10n.batchUrls,
              hintText: l10n.batchHint,
              alignLabelWithHint: true,
            ),
          ),
          if (_templates.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            DropdownButtonFormField<String?>(
              initialValue: _templateName,
              decoration: InputDecoration(labelText: l10n.templateName),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.filterAll),
                ),
                for (final template in _templates)
                  DropdownMenuItem<String?>(
                    value: template.name,
                    child: Text(template.name),
                  ),
              ],
              onChanged: (value) => setState(() {
                _templateName = value;
                _items = [];
              }),
            ),
          ],
          const SizedBox(height: Spacing.md),
          FilledButton.icon(
            onPressed: _busy ? null : _preview,
            icon: const Icon(Icons.preview_rounded),
            label: Text(l10n.parse),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: Spacing.lg),
            Text(
              '${ready.length} ${l10n.batchReady}'
              '${estimated == null ? '' : ' · ${formatBytes(estimated)}'}',
            ),
            if (_availableBytes != null) ...[
              Text('${l10n.availableSpace}: ${formatBytes(_availableBytes!)}'),
              if (estimated != null && estimated * 1.3 > _availableBytes!)
                Text(
                  l10n.lowSpaceWarning,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
            const SizedBox(height: Spacing.sm),
            for (final item in _items)
              ListTile(
                dense: true,
                title: Text(
                  item.sourceUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.error ??
                      (item.added
                          ? l10n.statusQueued
                          : item.playlist == null
                          ? l10n.parsing
                          : '${item.playlist!.segmentCount} ${l10n.segmentCount}'
                                '${item.estimatedBytes == null ? '' : ' · ${formatBytes(item.estimatedBytes!)}'}'),
                ),
                leading: Icon(
                  item.error != null
                      ? Icons.error_outline_rounded
                      : item.added
                      ? Icons.check_rounded
                      : Icons.movie_outlined,
                ),
              ),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: _busy || ready.isEmpty ? null : _addAll,
              icon: const Icon(Icons.download_rounded),
              label: Text(l10n.batchAdd),
            ),
          ],
        ],
      ),
    );
  }
}
