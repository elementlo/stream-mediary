import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:disk_usage/disk_usage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/mediary_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/storage_access.dart';
import '../../core/widgets/mediary_card.dart';
import '../../core/widgets/mediary_scaffold.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/status_badge.dart';
import '../../engine/engine_config.dart';
import '../../engine/m3u8/m3u8_parser.dart';
import '../../engine/m3u8/playlist.dart';
import '../../data/repositories/source_repository.dart';
import '../../providers/app_providers.dart';

class NewDownloadPage extends ConsumerStatefulWidget {
  const NewDownloadPage({super.key});

  @override
  ConsumerState<NewDownloadPage> createState() => _NewDownloadPageState();
}

class _NewDownloadPageState extends ConsumerState<NewDownloadPage> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _ivController = TextEditingController();
  final _titleController = TextEditingController();
  final List<_HeaderRow> _headers = [];

  bool _parsing = false;
  String? _error;
  ParseResult? _result;
  String _parsedUrl = '';
  Map<String, String> _parsedHeaders = const {};
  int _preflightEpoch = 0;
  int _selectedVariant = 0;
  String? _saveDir;
  bool _advancedOpen = false;
  bool _starting = false;
  bool _checking = false;
  MediaPlaylist? _selectedMedia;
  int? _estimatedBytes;
  int? _availableBytes;
  List<String> _recent = [];
  List<SourceTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    final repo = ref.read(sourceRepositoryProvider);
    final (recent, templates) = await (
      repo.recentUrls(),
      repo.templates(),
    ).wait;
    if (mounted) {
      setState(() {
        _recent = recent;
        _templates = templates;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _ivController.dispose();
    _titleController.dispose();
    for (final h in _headers) {
      h.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _headerMap => {
    for (final h in _headers)
      if (h.keyController.text.trim().isNotEmpty)
        h.keyController.text.trim(): h.valueController.text.trim(),
  };

  bool get _urlLooksValid {
    final uri = Uri.tryParse(_urlController.text.trim());
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  Future<void> _parse() async {
    final url = _urlController.text.trim();
    final headers = _headerMap;
    if (!_urlLooksValid) {
      setState(() => _error = AppLocalizations.of(context).errorInvalidUrl);
      return;
    }

    setState(() {
      _parsing = true;
      _error = null;
      _result = null;
      _selectedMedia = null;
      _preflightEpoch++;
    });

    final engine = ref.read(downloadEngineProvider);
    try {
      final result = await engine.parseForPreview(url, headers: headers);
      if (!mounted || _urlController.text.trim() != url) return;
      setState(() {
        _result = result;
        _parsedUrl = url;
        _parsedHeaders = headers;
        _selectedVariant = 0;
      });
      await _refreshPreflight();
    } on M3u8ParseException catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = AppLocalizations.of(context).errorParseFailed(e.message),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).errorParseFailed('$e'),
        );
      }
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  Future<void> _refreshPreflight() async {
    final result = _result;
    if (result == null) return;
    final epoch = ++_preflightEpoch;
    final selected = _selectedVariant;
    setState(() {
      _checking = true;
      _selectedMedia = null;
      _estimatedBytes = null;
    });
    try {
      final engine = ref.read(downloadEngineProvider);
      final MediaPlaylist media;
      if (result is MasterParseResult) {
        final parsed = await engine.parseForPreview(
          result.master.variants[selected].url,
          headers: _parsedHeaders,
        );
        if (parsed is! MediaParseResult) {
          throw const M3u8ParseException('Variant is not media');
        }
        media = parsed.media;
      } else {
        media = (result as MediaParseResult).media;
      }
      final estimate = await engine.estimateMediaBytes(
        media,
        headers: _parsedHeaders,
      );
      final dir = _saveDir ?? await ref.read(defaultSaveDirProvider.future);
      int? available;
      try {
        available = await DiskUsage.freeSpace(dir);
      } catch (_) {
        /* unsupported */
      }
      if (!mounted || result != _result || epoch != _preflightEpoch) return;
      setState(() {
        _selectedMedia = media;
        _estimatedBytes =
            estimate ??
            (result is MasterParseResult &&
                    result.master.variants[selected].bandwidth != null
                ? (result.master.variants[selected].bandwidth! *
                          media.totalDuration /
                          8)
                      .round()
                : null);
        _availableBytes = available;
      });
    } catch (e) {
      if (mounted && epoch == _preflightEpoch) {
        setState(
          () =>
              _error = AppLocalizations.of(context).errorParseFailed('$e'),
        );
      }
    } finally {
      if (mounted && epoch == _preflightEpoch) {
        setState(() => _checking = false);
      }
    }
  }

  void _applyTemplate(SourceTemplate template) {
    for (final row in _headers) {
      row.dispose();
    }
    _headers.clear();
    for (final entry in template.headers.entries) {
      final row = _HeaderRow();
      row.keyController.text = entry.key;
      row.valueController.text = entry.value;
      _headers.add(row);
    }
    setState(() {
      _advancedOpen = true;
      _result = null;
      _selectedMedia = null;
      _preflightEpoch++;
    });
  }

  Future<void> _saveTemplate() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).saveTemplate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).templateName,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              AppLocalizations.of(context).templatePrivacyHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await ref
        .read(sourceRepositoryProvider)
        .saveTemplate(SourceTemplate(name: name, headers: _headerMap));
    await _loadSources();
  }

  Future<void> _startDownload() async {
    final result = _result;
    if (result == null || _starting || _selectedMedia == null) return;
    if (_urlController.text.trim() != _parsedUrl ||
        !mapEquals(_headerMap, _parsedHeaders)) {
      setState(() {
        _result = null;
        _selectedMedia = null;
      });
      return;
    }
    setState(() => _starting = true);

    final engine = ref.read(downloadEngineProvider);
    final l10n = AppLocalizations.of(context);

    try {
      final media = _selectedMedia!;
      String effectiveUrl = _parsedUrl;

      switch (result) {
        case MasterParseResult(:final master):
          final variant = master.variants[_selectedVariant];
          effectiveUrl = variant.url;
        case MediaParseResult():
          break;
      }

      final id = const Uuid().v4();
      final request = DownloadRequest(
        url: effectiveUrl,
        sourceUrl: _parsedUrl,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        headers: _parsedHeaders,
        customKeyHex: _keyController.text.trim().isEmpty
            ? null
            : _keyController.text.trim(),
        customIvHex: _ivController.text.trim().isEmpty
            ? null
            : _ivController.text.trim(),
        saveDir: _saveDir,
      );

      await engine.startTask(id: id, request: request, playlist: media);
      await ref.read(sourceRepositoryProvider).remember(_parsedUrl);
      if (mounted) context.go('/downloads');
    } on M3u8ParseException catch (e) {
      if (mounted) setState(() => _error = l10n.errorParseFailed(e.message));
    } catch (e) {
      if (mounted) setState(() => _error = l10n.errorParseFailed('$e'));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _chooseDir() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await StorageAccess.hasAccess()) {
      final granted = await StorageAccess.requestAccess();
      if (!granted) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.storagePermissionHint)),
          );
        }
        return;
      }
    }
    try {
      final dir = await file_selector.getDirectoryPath(
        confirmButtonText: l10n.chooseDirectory,
      );
      if (dir != null) {
        setState(() => _saveDir = dir);
        if (_result != null) await _refreshPreflight();
      }
    } catch (_) {
      // Platform without directory picker; keep default.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MediaryScaffold(
      title: l10n.newDownload,
      maxWidth: Breakpoints.contentForm,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/downloads'),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _UrlField(
            controller: _urlController,
            label: l10n.m3u8UrlLabel,
            hint: l10n.m3u8UrlHint,
            onChanged: () => setState(() {
              _result = null;
              _selectedMedia = null;
              _preflightEpoch++;
            }),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final value = data?.text?.trim();
                if (value == null || !mounted) return;
                _urlController.text = value;
                setState(() {
                  _result = null;
                  _selectedMedia = null;
                });
              },
              icon: const Icon(Icons.content_paste_rounded, size: 16),
              label: Text(l10n.pasteClipboard),
            ),
          ),
          if (_recent.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              l10n.recentSources,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: Spacing.xs),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _recent
                    .take(5)
                    .map(
                      (url) => Padding(
                        padding: const EdgeInsets.only(right: Spacing.sm),
                        child: ActionChip(
                          label: Text(
                            Uri.tryParse(url)?.host ?? url,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () {
                            _urlController.text = url;
                            setState(() {
                              _result = null;
                              _selectedMedia = null;
                              _preflightEpoch++;
                            });
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: l10n.downloadTitle,
              hintText: l10n.downloadTitleHint,
            ),
          ),
          if (_templates.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              children: _templates
                  .map(
                    (template) => InputChip(
                      label: Text(template.name),
                      onPressed: () => _applyTemplate(template),
                      onDeleted: () async {
                        await ref
                            .read(sourceRepositoryProvider)
                            .deleteTemplate(template.name);
                        await _loadSources();
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: Spacing.md),
          _AdvancedSection(
            open: _advancedOpen,
            onToggle: () => setState(() => _advancedOpen = !_advancedOpen),
            headers: _headers,
            onAddHeader: () => setState(() => _headers.add(_HeaderRow())),
            onRemoveHeader: (row) => setState(() => _headers.remove(row)),
            onSaveTemplate: _saveTemplate,
            keyController: _keyController,
            ivController: _ivController,
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: _parsing || !_urlLooksValid ? null : _parse,
            icon: _parsing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded, size: 18),
            label: Text(_parsing ? l10n.parsing : l10n.parse),
          ),
          if (_error != null) ...[
            const SizedBox(height: Spacing.md),
            _ErrorBanner(message: _error!),
          ],
          if (_result != null) ...[
            const SizedBox(height: Spacing.xl),
            _PreviewCard(
              result: _result!,
              selectedVariant: _selectedVariant,
              onVariantChanged: (i) {
                setState(() => _selectedVariant = i);
                _refreshPreflight();
              },
              saveDir: _saveDir,
              onChooseDir: _chooseDir,
              onStart: _starting || _checking || _selectedMedia == null
                  ? null
                  : _startDownload,
              media: _selectedMedia,
              checking: _checking,
              estimatedBytes: _estimatedBytes,
              availableBytes: _availableBytes,
            ),
          ],
        ],
      ),
    );
  }
}

class _UrlField extends StatelessWidget {
  const _UrlField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: Spacing.xs,
            bottom: Spacing.sm - 2,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.link_rounded, size: 19),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
          ),
          keyboardType: TextInputType.url,
          autofillHints: const [AutofillHints.url],
        ),
      ],
    );
  }
}

/// Collapsible advanced options: request headers and key/IV overrides.
class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({
    required this.open,
    required this.onToggle,
    required this.headers,
    required this.onAddHeader,
    required this.onRemoveHeader,
    required this.onSaveTemplate,
    required this.keyController,
    required this.ivController,
  });

  final bool open;
  final VoidCallback onToggle;
  final List<_HeaderRow> headers;
  final VoidCallback onAddHeader;
  final ValueChanged<_HeaderRow> onRemoveHeader;
  final VoidCallback onSaveTemplate;
  final TextEditingController keyController;
  final TextEditingController ivController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return MediaryCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: Radii.lgAll,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.advancedSection, style: text.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          l10n.advancedHint,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: Motion.standard,
                    curve: Motion.enter,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: Motion.emphasized,
            sizeCurve: Motion.emphasizedCurve,
            crossFadeState: open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: context.mediaryHairline, height: 1),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    l10n.headerSection,
                    style: text.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  for (final row in headers)
                    _HeaderRowWidget(
                      row: row,
                      onRemove: () => onRemoveHeader(row),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onAddHeader,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(l10n.addHeader),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onSaveTemplate,
                      icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                      label: Text(l10n.saveTemplate),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    l10n.decryptSection,
                    style: text.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    l10n.decryptHint,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm + 2),
                  _KeyField(controller: keyController, label: l10n.customKey),
                  const SizedBox(height: Spacing.sm + 2),
                  _KeyField(controller: ivController, label: l10n.customIv),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyField extends StatelessWidget {
  const _KeyField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}

class _HeaderRow {
  final keyController = TextEditingController();
  final valueController = TextEditingController();

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _HeaderRowWidget extends StatelessWidget {
  const _HeaderRowWidget({required this.row, required this.onRemove});

  final _HeaderRow row;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: row.keyController,
              decoration: InputDecoration(
                hintText: l10n.headerKey,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            flex: 5,
            child: TextField(
              controller: row.valueController,
              decoration: InputDecoration(
                hintText: l10n.headerValue,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: Spacing.xs),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 17),
            tooltip: l10n.delete,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(36),
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.mediaryColors;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.dangerContainer.withValues(alpha: 0.6),
        borderRadius: Radii.mdAll,
        border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 17, color: colors.danger),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              message,
              style: text.bodyMedium?.copyWith(color: colors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Parse result: metrics grid, quality picker, destination and confirm action.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.result,
    required this.selectedVariant,
    required this.onVariantChanged,
    required this.saveDir,
    required this.onChooseDir,
    required this.onStart,
    required this.media,
    required this.checking,
    required this.estimatedBytes,
    required this.availableBytes,
  });

  final ParseResult result;
  final int selectedVariant;
  final ValueChanged<int> onVariantChanged;
  final String? saveDir;
  final VoidCallback onChooseDir;
  final VoidCallback? onStart;
  final MediaPlaylist? media;
  final bool checking;
  final int? estimatedBytes;
  final int? availableBytes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return MediaryCard(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: Spacing.sm),
              Text(l10n.previewSection, style: text.titleMedium),
              const Spacer(),
              switch (result) {
                MediaParseResult(:final media) => PillBadge(
                  label: media.encrypted
                      ? l10n.encryptedBadge
                      : l10n.notEncryptedBadge,
                  color: media.encrypted
                      ? context.mediaryColors.warning
                      : context.mediaryColors.success,
                ),
                MasterParseResult() => const SizedBox.shrink(),
              },
            ],
          ),
          const SizedBox(height: Spacing.lg),
          switch (result) {
            MasterParseResult(:final master) => _VariantPicker(
              master: master,
              selected: selectedVariant,
              onChanged: onVariantChanged,
            ),
            MediaParseResult(:final media) => _MediaSummary(media: media),
          },
          if (checking) const LinearProgressIndicator(),
          if (media != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              '${l10n.segmentCount}: ${media!.segmentCount} · '
              '${l10n.totalDuration}: ${formatDuration(media!.totalDuration)}',
              style: text.bodySmall,
            ),
          ],
          if (estimatedBytes != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              '${l10n.estimatedSize}: ${formatBytes(estimatedBytes!)} '
              '(${l10n.estimatedSizeHint})',
              style: text.bodySmall,
            ),
          ],
          if (availableBytes != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              '${l10n.availableSpace}: ${formatBytes(availableBytes!)}',
              style: text.bodySmall,
            ),
          ],
          if (estimatedBytes != null &&
              availableBytes != null &&
              estimatedBytes! * 1.3 > availableBytes!) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              l10n.lowSpaceWarning,
              style: text.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          const SizedBox(height: Spacing.lg),
          _DestinationRow(saveDir: saveDir, onChooseDir: onChooseDir),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.startDownloadHint,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(l10n.startDownload),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantPicker extends StatelessWidget {
  const _VariantPicker({
    required this.master,
    required this.selected,
    required this.onChanged,
  });

  final MasterPlaylist master;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.mediaryColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: Spacing.xs,
            bottom: Spacing.sm - 2,
          ),
          child: Text(
            l10n.selectVariant,
            style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        for (var i = 0; i < master.variants.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm - 2),
            child: _VariantTile(
              variant: master.variants[i],
              selected: i == selected,
              onTap: () => onChanged(i),
              accent: scheme.primary,
              hairline: colors.hairline,
              surface: scheme.surfaceContainer,
              container: scheme.primaryContainer,
            ),
          ),
      ],
    );
  }
}

class _VariantTile extends StatelessWidget {
  const _VariantTile({
    required this.variant,
    required this.selected,
    required this.onTap,
    required this.accent,
    required this.hairline,
    required this.surface,
    required this.container,
  });

  final Variant variant;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final Color hairline;
  final Color surface;
  final Color container;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final detail = [
      if (variant.codecs != null) variant.codecs,
      if (variant.bandwidth != null)
        '${(variant.bandwidth! / 1000).round()} kbps',
    ].whereType<String>().join(' · ');

    return Material(
      color: selected ? container : surface,
      borderRadius: Radii.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.mdAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.md - 2,
          ),
          decoration: BoxDecoration(
            borderRadius: Radii.mdAll,
            border: Border.all(
              color: selected ? accent : hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _RadioDot(selected: selected, color: accent, hairline: hairline),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(variant.displayName, style: text.titleMedium),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        detail,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({
    required this.selected,
    required this.color,
    required this.hairline,
  });

  final bool selected;
  final Color color;
  final Color hairline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? color : hairline,
          width: selected ? 5 : 1.5,
        ),
      ),
    );
  }
}

class _MediaSummary extends StatelessWidget {
  const _MediaSummary({required this.media});

  final MediaPlaylist media;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.mediaryColors;

    final keyMethod = media.encrypted
        ? media.segments
              .firstWhere((s) => s.keyInfo != null)
              .keyInfo!
              .method
              .label
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatGrid(
          children: [
            StatTile(
              label: l10n.segmentCount,
              value: '${media.segmentCount}',
              icon: Icons.view_module_rounded,
            ),
            StatTile(
              label: l10n.totalDuration,
              value: formatDuration(media.totalDuration),
              icon: Icons.schedule_rounded,
            ),
            StatTile(
              label: l10n.encrypted,
              value: keyMethod ?? l10n.notEncrypted,
              icon: media.encrypted
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              valueColor: media.encrypted ? colors.warning : colors.success,
            ),
          ],
        ),
        if (media.isLive) ...[
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Icon(Icons.live_tv_rounded, size: 15, color: colors.danger),
              const SizedBox(width: Spacing.xs + 2),
              Text(
                l10n.liveBadge,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.danger),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({required this.saveDir, required this.onChooseDir});

  final String? saveDir;
  final VoidCallback onChooseDir;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.mediaryColors;

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: Radii.mdAll,
      child: InkWell(
        onTap: onChooseDir,
        borderRadius: Radii.mdAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.md - 2,
          ),
          decoration: BoxDecoration(
            borderRadius: Radii.mdAll,
            border: Border.all(color: colors.hairline),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_rounded,
                size: 17,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.sm + 1),
              Expanded(
                child: Text(
                  saveDir ?? l10n.chooseDirectory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
