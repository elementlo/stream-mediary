import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
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
  final List<_HeaderRow> _headers = [];

  bool _parsing = false;
  String? _error;
  ParseResult? _result;
  String _parsedUrl = '';
  int _selectedVariant = 0;
  String? _saveDir;
  bool _advancedOpen = false;

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _ivController.dispose();
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
    if (!_urlLooksValid) {
      setState(() => _error = AppLocalizations.of(context).errorInvalidUrl);
      return;
    }

    setState(() {
      _parsing = true;
      _error = null;
      _result = null;
    });

    final engine = ref.read(downloadEngineProvider);
    try {
      final result = await engine.parseForPreview(url, headers: _headerMap);
      setState(() {
        _result = result;
        _parsedUrl = url;
        _selectedVariant = 0;
      });
    } on M3u8ParseException catch (e) {
      setState(() =>
          _error = AppLocalizations.of(context).errorParseFailed(e.message));
    } catch (e) {
      setState(
          () => _error = AppLocalizations.of(context).errorParseFailed('$e'));
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  Future<void> _startDownload() async {
    final result = _result;
    if (result == null) return;

    final engine = ref.read(downloadEngineProvider);
    final l10n = AppLocalizations.of(context);

    try {
      MediaPlaylist media;
      String effectiveUrl = _parsedUrl;

      switch (result) {
        case MasterParseResult(:final master):
          final variant = master.variants[_selectedVariant];
          effectiveUrl = variant.url;
          final content = await engine.parseForPreview(
            variant.url,
            headers: _headerMap,
          );
          if (content is! MediaParseResult) {
            setState(() => _error = l10n.errorParseFailed('variant not media'));
            return;
          }
          media = content.media;
        case MediaParseResult(media: final parsed):
          media = parsed;
      }

      final id = const Uuid().v4();
      final request = DownloadRequest(
        url: effectiveUrl,
        headers: _headerMap,
        customKeyHex:
            _keyController.text.trim().isEmpty ? null : _keyController.text.trim(),
        customIvHex:
            _ivController.text.trim().isEmpty ? null : _ivController.text.trim(),
        saveDir: _saveDir,
      );

      await engine.startTask(id: id, request: request, playlist: media);
      if (mounted) context.go('/downloads');
    } on M3u8ParseException catch (e) {
      if (mounted) setState(() => _error = l10n.errorParseFailed(e.message));
    } catch (e) {
      if (mounted) setState(() => _error = l10n.errorParseFailed('$e'));
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
      if (dir != null) setState(() => _saveDir = dir);
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
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: Spacing.md),
          _AdvancedSection(
            open: _advancedOpen,
            onToggle: () => setState(() => _advancedOpen = !_advancedOpen),
            headers: _headers,
            onAddHeader: () => setState(() => _headers.add(_HeaderRow())),
            onRemoveHeader: (row) => setState(() => _headers.remove(row)),
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
              onVariantChanged: (i) => setState(() => _selectedVariant = i),
              saveDir: _saveDir,
              onChooseDir: _chooseDir,
              onStart: _startDownload,
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
          padding: const EdgeInsets.only(left: Spacing.xs, bottom: Spacing.sm - 2),
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
    required this.keyController,
    required this.ivController,
  });

  final bool open;
  final VoidCallback onToggle;
  final List<_HeaderRow> headers;
  final VoidCallback onAddHeader;
  final ValueChanged<_HeaderRow> onRemoveHeader;
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
                  Icon(Icons.tune_rounded,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.advancedSection, style: text.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          l10n.advancedHint,
                          style: text.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: Motion.standard,
                    curve: Motion.enter,
                    child: Icon(Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: Motion.emphasized,
            sizeCurve: Motion.emphasizedCurve,
            crossFadeState:
                open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
                    style: text.titleSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: Spacing.sm),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    l10n.decryptSection,
                    style: text.titleSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    l10n.decryptHint,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: Spacing.sm + 2),
                  _KeyField(
                    controller: keyController,
                    label: l10n.customKey,
                  ),
                  const SizedBox(height: Spacing.sm + 2),
                  _KeyField(
                    controller: ivController,
                    label: l10n.customIv,
                  ),
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
              foregroundColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
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
  });

  final ParseResult result;
  final int selectedVariant;
  final ValueChanged<int> onVariantChanged;
  final String? saveDir;
  final VoidCallback onChooseDir;
  final VoidCallback onStart;

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
          const SizedBox(height: Spacing.lg),
          _DestinationRow(saveDir: saveDir, onChooseDir: onChooseDir),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.startDownloadHint,
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
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
          padding: const EdgeInsets.only(left: Spacing.xs, bottom: Spacing.sm - 2),
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
      if (variant.bandwidth != null) '${(variant.bandwidth! / 1000).round()} kbps',
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
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
              Icon(Icons.folder_rounded,
                  size: 17, color: scheme.onSurfaceVariant),
              const SizedBox(width: Spacing.sm + 1),
              Expanded(
                child: Text(
                  saveDir ?? l10n.chooseDirectory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}