import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../data/repositories/settings_repository.dart';
import '../../engine/merge/ffmpeg_remuxer.dart';
import '../../providers/app_providers.dart';

/// ffmpeg probe result.
final ffmpegProbeProvider = FutureProvider<FfmpegProbeResult>((ref) async {
  const remuxer = FfmpegRemuxer();
  final settings = ref.watch(settingsRepositoryProvider);
  final userPath = await settings.ffmpegPath();
  return remuxer.probe(userPath: userPath);
});

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _taskConcurrency = SettingsRepository.defaultTaskConcurrency;
  String _mergePreference = 'prefer_mp4';
  String? _saveDir;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsRepositoryProvider);
    final concurrency = await settings.taskConcurrency();
    final merge = await settings.mergePreference();
    final dir = await settings.defaultSaveDir();
    if (mounted) {
      setState(() {
        _taskConcurrency = concurrency;
        _mergePreference = merge;
        _saveDir = dir;
        _loaded = true;
      });
    }
  }

  Future<void> _chooseSaveDir() async {
    try {
      final dir = await file_selector.getDirectoryPath(
        confirmButtonText: AppLocalizations.of(context).chooseDirectory,
      );
      if (dir != null) {
        setState(() => _saveDir = dir);
        await ref.read(settingsRepositoryProvider).setDefaultSaveDir(dir);
      }
    } catch (_) {
      // Platform without directory picker; keep current value.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final ffmpeg = ref.watch(ffmpegProbeProvider);

    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(l10n.concurrency),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(l10n.concurrency),
                      const Spacer(),
                      Text('$_taskConcurrency',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Slider(
                    value: _taskConcurrency.toDouble(),
                    min: 1,
                    max: 16,
                    divisions: 15,
                    onChanged: (v) async {
                      setState(() => _taskConcurrency = v.round());
                      await ref
                          .read(settingsRepositoryProvider)
                          .setTaskConcurrency(_taskConcurrency);
                      ref
                          .read(downloadEngineProvider)
                          .updateConfig(ref
                              .read(downloadEngineProvider)
                              .config
                              .copyWith(taskConcurrency: _taskConcurrency));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l10n.defaultSaveDir),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_rounded),
              title: Text(
                _saveDir ?? l10n.chooseDirectory,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _chooseSaveDir,
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l10n.themeMode),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_rounded),
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_rounded),
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_rounded),
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (sel) =>
                    ref.read(themeModeProvider.notifier).set(sel.first),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l10n.mergePreference),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'ts_only',
                    label: Text(l10n.mergeTsOnly),
                  ),
                  ButtonSegment(
                    value: 'prefer_mp4',
                    label: Text(l10n.mergePreferMp4),
                  ),
                ],
                selected: {_mergePreference},
                onSelectionChanged: (sel) async {
                  setState(() => _mergePreference = sel.first);
                  await ref
                      .read(settingsRepositoryProvider)
                      .setMergePreference(_mergePreference);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('ffmpeg'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ffmpeg.when(
                    data: (probe) => Row(
                      children: [
                        Icon(
                          probe.available
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: probe.available
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            probe.available
                                ? '${l10n.ffmpegDetected}: ${probe.path}'
                                : l10n.ffmpegNotFound,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l10n.about),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_rounded),
              title: Text(l10n.appTitle),
              subtitle: Text('${l10n.version} 1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
