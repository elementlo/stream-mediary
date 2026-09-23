import 'dart:async';
import 'dart:convert';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/repositories/settings_repository.dart';
import '../engine/download_engine.dart';
import '../engine/engine_store.dart';
import '../engine/task/task_state.dart';

class QueuePolicyCoordinator {
  QueuePolicyCoordinator(this.engine, this.store, this.settings);
  final DownloadEngine engine;
  final EngineTaskStore store;
  final SettingsRepository settings;
  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();
  StreamSubscription<List<ConnectivityResult>>? _networkSub;
  StreamSubscription<BatteryState>? _batterySub;
  Timer? _poll;
  bool _refreshing = false;
  bool _refreshAgain = false;
  final Set<String> _pausedByPolicy = {};

  Future<void> start() async {
    engine.setQueueAllowed(false);
    try {
      final saved = await settings.raw('policy_paused_ids');
      if (saved != null) {
        _pausedByPolicy.addAll((jsonDecode(saved) as List).whereType<String>());
      }
    } catch (_) {
      /* ignore stale state */
    }
    _networkSub = _connectivity.onConnectivityChanged.listen((_) => refresh());
    _batterySub = _battery.onBatteryStateChanged.listen((_) => refresh());
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    await refresh();
  }

  Future<void> refresh() async {
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      final wifiOnly = await settings.flag(SettingsRepository.keyWifiOnly);
      final chargingOnly = await settings.flag(
        SettingsRepository.keyChargingOnly,
      );
      final sequential = await settings.flag(
        SettingsRepository.keySequentialQueue,
      );
      final configured = await settings.taskConcurrency();
      engine.updateConfig(
        engine.config.copyWith(taskConcurrency: sequential ? 1 : configured),
      );
      var allowed = true;
      if (wifiOnly) {
        final connections = await _connectivity.checkConnectivity();
        allowed =
            connections.contains(ConnectivityResult.wifi) ||
            connections.contains(ConnectivityResult.ethernet);
      }
      if (allowed && chargingOnly) {
        final state = await _battery.batteryState;
        allowed = state == BatteryState.charging || state == BatteryState.full;
      }
      engine.setQueueAllowed(allowed);
      if (!allowed) {
        for (final task in await store.loadAllTasks()) {
          if (task.state == TaskState.downloading) {
            _pausedByPolicy.add(task.id);
            await engine.pauseTask(task.id);
          }
        }
      } else {
        for (final id in _pausedByPolicy.toList()) {
          final task = await store.loadTask(id);
          if (task?.state == TaskState.paused) await engine.resumeTask(id);
          _pausedByPolicy.remove(id);
        }
      }
      await settings.setRaw(
        'policy_paused_ids',
        jsonEncode(_pausedByPolicy.toList()),
      );
    } catch (_) {
      // If a platform cannot report policy state, keep queued work held
      // until the next refresh instead of using mobile data unexpectedly.
    } finally {
      _refreshing = false;
      if (_refreshAgain) {
        _refreshAgain = false;
        unawaited(refresh());
      }
    }
  }

  void dispose() {
    _networkSub?.cancel();
    _batterySub?.cancel();
    _poll?.cancel();
  }
}
