import 'dart:io';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/user_error.dart';
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
import '../update/update_dialog.dart';

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
  int _segmentConcurrency = SettingsRepository.defaultSegmentConcurrency;
  String _mergePreference = 'prefer_mp4';
  String? _saveDir;
  bool _loaded = false;
  bool _wifiOnly = false;
  bool _chargingOnly = false;
  bool _sequentialQueue = false;
  bool _completionNotifications = false;
  final TextEditingController _proxyHostController = TextEditingController();
  final TextEditingController _proxyPortController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsRepositoryProvider);
    final (
      (
        concurrency,
        segmentConcurrency,
        merge,
        dir,
        wifi,
      ),
      (
        charging,
        sequential,
        notifications,
        proxyHost,
        proxyPort,
      ),
    ) = await (
      (
        settings.taskConcurrency(),
        settings.segmentConcurrency(),
        settings.mergePreference(),
        settings.defaultSaveDir(),
        settings.flag(SettingsRepository.keyWifiOnly),
      ).wait,
      (
        settings.flag(SettingsRepository.keyChargingOnly),
        settings.flag(SettingsRepository.keySequentialQueue),
        settings.flag(SettingsRepository.keyCompletionNotifications),
        settings.proxyHost(),
        settings.proxyPort(),
      ).wait,
    ).wait;
    if (mounted) {
      setState(() {
        _taskConcurrency = concurrency;
        _segmentConcurrency = segmentConcurrency;
        _mergePreference = merge;
        _saveDir = dir;
        _wifiOnly = wifi;
        _chargingOnly = charging;
        _sequentialQueue = sequential;
        _completionNotifications = notifications;
        _proxyHostController.text = proxyHost ?? '';
        _proxyPortController.text = proxyPort == null ? '' : '$proxyPort';
        _loaded = true;
      });
    }
  }

  Future<void> _saveProxy() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final settings = ref.read(settingsRepositoryProvider);
    final host = _proxyHostController.text.trim();
    final portText = _proxyPortController.text.trim();
    int? port;
    if (portText.isNotEmpty) {
      port = int.tryParse(portText);
      if (port == null || port <= 0 || port > 65535) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.proxyInvalidPort)),
        );
        return;
      }
    }
    await settings.setProxyHost(host);
    await settings.setProxyPort(port);
    final engine = ref.read(downloadEngineProvider);
    engine.updateConfig(
      engine.config.copyWith(proxyHost: host, proxyPort: port),
    );
    // Keep update-check/download traffic on the same proxy as the engine.
    ref.read(updateServiceProvider).updateProxy(host, port);
    messenger.showSnackBar(SnackBar(content: Text(l10n.proxySaved)));
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
        ref.invalidate(defaultSaveDirProvider);
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
            label: l10n.concurrency,
            value: _taskConcurrency,
            min: 1,
            max: 16,
            onChanged: (v) async {
              setState(() => _taskConcurrency = v.round());
              await ref
                  .read(settingsRepositoryProvider)
                  .setTaskConcurrency(_taskConcurrency);
              final engine = ref.read(downloadEngineProvider);
              engine.updateConfig(
                engine.config.copyWith(
                  taskConcurrency: _sequentialQueue ? 1 : _taskConcurrency,
                ),
              );
            },
          ),
          _ConcurrencySection(
            label: l10n.segmentConcurrency,
            hint: l10n.segmentConcurrencyHint,
            value: _segmentConcurrency,
            min: 2,
            max: 32,
            onChanged: (v) async {
              setState(() => _segmentConcurrency = v.round());
              await ref
                  .read(settingsRepositoryProvider)
                  .setSegmentConcurrency(_segmentConcurrency);
              final engine = ref.read(downloadEngineProvider);
              engine.updateConfig(
                engine.config.copyWith(
                  segmentConcurrency: _segmentConcurrency,
                ),
              );
            },
          ),
          SectionHeader(l10n.queuePolicy),
          MediaryCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.sequentialQueue),
                  value: _sequentialQueue,
                  onChanged: (value) async {
                    setState(() => _sequentialQueue = value);
                    await ref
                        .read(settingsRepositoryProvider)
                        .setFlag(SettingsRepository.keySequentialQueue, value);
                    await ref.read(queuePolicyProvider).refresh();
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.wifiOnly),
                  value: _wifiOnly,
                  onChanged: (value) async {
                    setState(() => _wifiOnly = value);
                    await ref
                        .read(settingsRepositoryProvider)
                        .setFlag(SettingsRepository.keyWifiOnly, value);
                    await ref.read(queuePolicyProvider).refresh();
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.chargingOnly),
                  value: _chargingOnly,
                  onChanged: (value) async {
                    setState(() => _chargingOnly = value);
                    await ref
                        .read(settingsRepositoryProvider)
                        .setFlag(SettingsRepository.keyChargingOnly, value);
                    await ref.read(queuePolicyProvider).refresh();
                  },
                ),
              ],
            ),
          ),
          SectionHeader(l10n.completionNotifications),
          MediaryCard(
            child: SwitchListTile(
              title: Text(l10n.completionNotifications),
              subtitle: Text(l10n.completionNotificationsHint),
              value: _completionNotifications,
              onChanged: (value) async {
                final enabled =
                    !value ||
                    await ref
                        .read(completionNotificationsProvider)
                        .requestPermission();
                if (!context.mounted) return;
                if (!enabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.notificationPermissionDenied)),
                  );
                  return;
                }
                setState(() => _completionNotifications = value);
                await ref
                    .read(settingsRepositoryProvider)
                    .setFlag(
                      SettingsRepository.keyCompletionNotifications,
                      value,
                    );
              },
            ),
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
                ButtonSegment(value: 'ts_only', label: Text(l10n.mergeTsOnly)),
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
                engine.updateConfig(
                  engine.config.copyWith(
                    preferMp4: _mergePreference == 'prefer_mp4',
                  ),
                );
              },
            ),
          ),
          SectionHeader(l10n.downloadProxy),
          MediaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.downloadProxyHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _proxyHostController,
                        decoration: InputDecoration(
                          labelText: l10n.proxyHost,
                          hintText: l10n.proxyHostHint,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _proxyPortController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.proxyPort,
                          hintText: l10n.proxyPortHint,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _saveProxy,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('ffmpeg'),
          MediaryCard(
            child: ffmpeg.when(
              data: (probe) => _FfmpegStatus(probe: probe, l10n: l10n),
              loading: () => const LinearProgressIndicator(),
              error: (e, st) {
                logUserError('Check ffmpeg availability', e, st);
                return Text(
                  l10n.ffmpegNotFound,
                  style: TextStyle(color: context.mediaryColors.danger),
                );
              },
            ),
          ),
          SectionHeader(l10n.about),
          MediaryCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.info_rounded,
                  title: l10n.appTitle,
                  subtitle: ref
                      .watch(appVersionProvider)
                      .maybeWhen(
                        data: (v) => '${l10n.version} $v',
                        orElse: () => l10n.version,
                      ),
                ),
                if (!Platform.isIOS) ...[
                  Divider(height: 1, color: context.mediaryHairline),
                  InkWell(
                    onTap: () =>
                        checkAndPromptUpdate(context, ref, manual: true),
                    child: _SettingRow(
                      icon: Icons.system_update_rounded,
                      title: l10n.checkUpdate,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Concurrency slider with a live numeric readout.
class _ConcurrencySection extends StatelessWidget {
  const _ConcurrencySection({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.hint,
  });

  final String label;
  final String? hint;
  final int value;
  final int min;
  final int max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md, left: Spacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
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
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                onChanged: onChanged,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                child: Row(
                  children: [
                    Text('$min', style: text.labelSmall),
                    const Spacer(),
                    Text('$max', style: text.labelSmall),
                  ],
                ),
              ),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: Spacing.sm,
                    left: Spacing.xs,
                    right: Spacing.xs,
                  ),
                  child: Text(
                    hint!,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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
            probe.available ? Icons.check_rounded : Icons.priority_high_rounded,
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
                    label: probe.available
                        ? l10n.mergePreferMp4
                        : l10n.mergeTsOnly,
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
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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
