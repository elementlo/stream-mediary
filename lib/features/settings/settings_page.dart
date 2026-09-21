import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/platform/platform_profile.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/mediary_colors.dart';
import '../../core/utils/storage_access.dart';
import '../../core/widgets/mediary_card.dart';
import '../../core/widgets/mediary_scaffold.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
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
    final (concurrency, merge, dir) = await (
      settings.taskConcurrency(),
      settings.mergePreference(),
      settings.defaultSaveDir(),
    ).wait;
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
        await ref.read(settingsRepositoryProvider).setDefaultSaveDir(dir);
        ref.read(downloadEngineProvider).defaultSaveDir = dir;
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
      return MediaryScaffold(
        title: l10n.settings,
        maxWidth: Breakpoints.contentForm,
        child: const Padding(
          padding: EdgeInsets.only(top: Spacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MediaryScaffold(
      title: l10n.settings,
      maxWidth: Breakpoints.contentForm,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ConcurrencySection(
            value: _taskConcurrency,
            onChanged: (v) async {
              setState(() => _taskConcurrency = v.round());
              await ref
                  .read(settingsRepositoryProvider)
                  .setTaskConcurrency(_taskConcurrency);
              final engine = ref.read(downloadEngineProvider);
              engine.updateConfig(engine.config
                  .copyWith(taskConcurrency: _taskConcurrency));
            },
          ),
          SectionHeader(l10n.defaultSaveDir),
          MediaryCard(
            padding: EdgeInsets.zero,
            onTap: _chooseSaveDir,
            child: _SettingRow(
              icon: Icons.folder_rounded,
              title: _saveDir ?? l10n.chooseDirectory,
              subtitle: _saveDir == null ? l10n.noSaveDir : null,
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SectionHeader(l10n.themeMode),
          MediaryCard(
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_rounded, size: 16),
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_rounded, size: 16),
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_rounded, size: 16),
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (sel) =>
                  ref.read(themeModeProvider.notifier).set(sel.first),
            ),
          ),
          SectionHeader(l10n.mergePreference),
          MediaryCard(
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
              showSelectedIcon: false,
              onSelectionChanged: (sel) async {
                setState(() => _mergePreference = sel.first);
                await ref
                    .read(settingsRepositoryProvider)
                    .setMergePreference(_mergePreference);
                final engine = ref.read(downloadEngineProvider);
                engine.updateConfig(engine.config.copyWith(
                  preferMp4: _mergePreference == 'prefer_mp4',
                ));
              },
            ),
          ),
          const SectionHeader('ffmpeg'),
          MediaryCard(
            child: ffmpeg.when(
              data: (probe) => _FfmpegStatus(probe: probe, l10n: l10n),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                '$e',
                style: TextStyle(color: context.mediaryColors.danger),
              ),
            ),
          ),
          SectionHeader(l10n.about),
          MediaryCard(
            padding: EdgeInsets.zero,
            child: _SettingRow(
              icon: Icons.info_rounded,
              title: l10n.appTitle,
              subtitle: ref.watch(appVersionProvider).maybeWhen(
                    data: (v) => '${l10n.version} $v',
                    orElse: () => l10n.version,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Task concurrency slider with a live numeric readout.
class _ConcurrencySection extends StatelessWidget {
  const _ConcurrencySection({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: Spacing.md,
            left: Spacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.concurrency,
                  style: text.titleSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: Radii.smAll,
                ),
                child: Text(
                  '$value',
                  style: text.labelMedium?.copyWith(color: scheme.primary),
                ),
              ),
            ],
          ),
        ),
        MediaryCard(
          child: Column(
            children: [
              Slider(
                value: value.toDouble(),
                min: 1,
                max: 16,
                divisions: 15,
                onChanged: onChanged,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                child: Row(
                  children: [
                    Text('1', style: text.labelSmall),
                    const Spacer(),
                    Text('16', style: text.labelSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FfmpegStatus extends StatelessWidget {
  const _FfmpegStatus({required this.probe, required this.l10n});

  final FfmpegProbeResult probe;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.mediaryColors;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (probe.available ? colors.success : colors.warning)
                .withValues(alpha: 0.12),
            borderRadius: Radii.smAll,
          ),
          child: Icon(
            probe.available
                ? Icons.check_rounded
                : Icons.priority_high_rounded,
            size: 17,
            color: probe.available ? colors.success : colors.warning,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      probe.available
                          ? l10n.ffmpegDetected
                          : l10n.ffmpegNotFound,
                      style: text.titleMedium,
                    ),
                  ),
                  PillBadge(
                    label: probe.available ? l10n.mergePreferMp4 : l10n.mergeTsOnly,
                    color: probe.available ? colors.success : colors.warning,
                  ),
                ],
              ),
              if (probe.available && probe.path != null) ...[
                const SizedBox(height: 3),
                Text(
                  probe.path!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Icon + title + optional subtitle row, used inside cards.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final profile = context.platformProfile;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: profile.isDesktop ? Spacing.xl : Spacing.lg,
        vertical: Spacing.md + 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (trailing case final Widget t) t,
        ],
      ),
    );
  }
}