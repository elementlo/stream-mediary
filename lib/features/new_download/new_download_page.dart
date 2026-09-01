import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/formatters.dart';
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

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _ivController.dispose();
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
      setState(() => _error = AppLocalizations.of(context)
          .errorParseFailed(e.message));
    } catch (e) {
      setState(() => _error =
          AppLocalizations.of(context).errorParseFailed('$e'));
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  Future<void> _startDownload() async {
    final result = _result;
    if (result == null) return;

    final engine = ref.read(downloadEngineProvider);
    final l10n = AppLocalizations.of(context);

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
      customKeyHex: _keyController.text.trim().isEmpty
          ? null
          : _keyController.text.trim(),
      customIvHex: _ivController.text.trim().isEmpty
          ? null
          : _ivController.text.trim(),
      saveDir: _saveDir,
    );

    await engine.startTask(id: id, request: request, playlist: media);
    if (mounted) context.go('/downloads');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newDownload),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/downloads'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: l10n.m3u8UrlLabel,
              hintText: l10n.m3u8UrlHint,
              prefixIcon: const Icon(Icons.link_rounded),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: Text(l10n.advancedOptions),
            leading: const Icon(Icons.tune_rounded),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.customHeaders,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final h in _headers) _HeaderRowWidget(row: h),
                    TextButton.icon(
                      onPressed: () => setState(
                          () => _headers.add(_HeaderRow())),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addHeader),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _keyController,
                      decoration:
                          InputDecoration(labelText: l10n.customKey),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ivController,
                      decoration:
                          InputDecoration(labelText: l10n.customIv),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _parsing ? null : _parse,
            icon: _parsing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded),
            label: Text(_parsing ? l10n.parsing : l10n.parse),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            _PreviewCard(
              result: _result!,
              selectedVariant: _selectedVariant,
              onVariantChanged: (i) =>
                  setState(() => _selectedVariant = i),
              saveDir: _saveDir,
              onChooseDir: _chooseDir,
              onStart: _startDownload,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _chooseDir() async {
    try {
      final dir = await file_selector.getDirectoryPath(
        confirmButtonText: AppLocalizations.of(context).chooseDirectory,
      );
      if (dir != null) setState(() => _saveDir = dir);
    } catch (_) {
      // Platform without directory picker; keep default.
    }
  }
}

class _HeaderRow {
  final keyController = TextEditingController();
  final valueController = TextEditingController();
}

class _HeaderRowWidget extends StatelessWidget {
  const _HeaderRowWidget({required this.row});

  final _HeaderRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: row.keyController,
              decoration: InputDecoration(
                labelText: l10n.headerKey,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: row.valueController,
              decoration: InputDecoration(
                labelText: l10n.headerValue,
                isDense: true,
              ),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Text(l10n.preview,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            switch (result) {
              MasterParseResult(:final master) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.selectVariant,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (var i = 0; i < master.variants.length; i++)
                      RadioListTile<int>(
                        value: i,
                        groupValue: selectedVariant,
                        onChanged: (v) =>
                            v != null ? onVariantChanged(v) : null,
                        title: Text(master.variants[i].displayName),
                        subtitle: Text(master.variants[i].codecs ?? ''),
                        dense: true,
                      ),
                  ],
                ),
              MediaParseResult(:final media) => _MediaSummary(media: media),
            },
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onChooseDir,
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: Text(saveDir ?? l10n.chooseDirectory),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.download_rounded),
                label: Text(l10n.startDownload),
              ),
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _InfoRow(
          icon: Icons.video_file_rounded,
          label: l10n.segmentCount,
          value: '${media.segmentCount}',
        ),
        _InfoRow(
          icon: Icons.schedule_rounded,
          label: l10n.totalDuration,
          value: formatDuration(media.totalDuration),
        ),
        _InfoRow(
          icon: media.encrypted
              ? Icons.lock_rounded
              : Icons.lock_open_rounded,
          label: media.encrypted ? l10n.encrypted : l10n.notEncrypted,
          value: media.encrypted
              ? (media.segments
                      .firstWhere((s) => s.keyInfo != null)
                      .keyInfo!
                      .method
                      .label)
              : '',
        ),
        if (media.isLive)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.live_tv_rounded,
                    size: 16, color: scheme.error),
                const SizedBox(width: 4),
                Text('LIVE',
                    style: TextStyle(color: scheme.error, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
