import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../data/repositories/settings_repository.dart';
import '../engine/download_engine.dart';
import '../engine/engine_events.dart';
import '../engine/engine_store.dart';
import '../engine/task/task_state.dart';

class CompletionNotifications {
  CompletionNotifications(this.engine, this.store, this.settings, this.router);
  final DownloadEngine engine;
  final EngineTaskStore store;
  final SettingsRepository settings;
  final GoRouter router;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<EngineEvent>? _subscription;
  bool _ready = false;

  /// Task ids already notified about a disk-full pause, so a task that
  /// pauses/resumes/pauses again does not spam the user. Cleared when the
  /// task leaves the disk-full paused state.
  final Set<String> _diskFullNotified = {};

  Future<void> start() async {
    try {
      final category = DarwinNotificationCategory(
        'download_complete',
        actions: [
          DarwinNotificationAction.plain(
            'play',
            '播放',
            options: {DarwinNotificationActionOption.foreground},
          ),
          DarwinNotificationAction.plain(
            'share',
            '分享',
            options: {DarwinNotificationActionOption.foreground},
          ),
        ],
      );
      await _plugin.initialize(
        InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            notificationCategories: [category],
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            notificationCategories: [category],
          ),
          linux: const LinuxInitializationSettings(defaultActionName: 'Open'),
          windows: const WindowsInitializationSettings(
            appName: 'Mediary',
            appUserModelId: 'Element.Mediary.Desktop',
            guid: '8c787a8c-7ef5-45f5-9940-5f4e47d5b161',
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final id = response.payload;
          if (id == null || id.isEmpty) return;
          if (response.actionId == 'share') {
            unawaited(_share(id));
          } else {
            router.go('/player/$id');
          }
        },
      );
      _ready = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        final id = launch?.notificationResponse?.payload;
        if (id != null && id.isNotEmpty) {
          if (launch?.notificationResponse?.actionId == 'share') {
            unawaited(_share(id));
          } else {
            router.go('/player/$id');
          }
        }
      }
    } catch (_) {
      _ready = false;
    }
    _subscription = engine.events.listen((event) {
      if (event is TaskCompletedEvent) {
        unawaited(_notify(event));
      } else if (event is TaskStateChangedEvent) {
        _onStateChanged(event);
      }
    });
  }

  void _onStateChanged(TaskStateChangedEvent event) {
    final diskFullPaused =
        event.diskFull && event.state == TaskState.paused;
    if (diskFullPaused) {
      if (_diskFullNotified.add(event.taskId)) {
        unawaited(_notifyDiskFull(event.taskId));
      }
    } else {
      // Task resumed or moved on: allow a future disk-full pause to notify.
      _diskFullNotified.remove(event.taskId);
    }
  }

  Future<void> _share(String id) async {
    final task = await store.loadTask(id);
    final path = task?.outputPath;
    if (path == null || !await File(path).exists()) {
      router.go('/history');
      return;
    }
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    } catch (_) {
      router.go('/history');
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: false, sound: true) ??
          false;
    }
    if (Platform.isMacOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: false, sound: true) ??
          false;
    }
    return true;
  }

  Future<void> _notify(TaskCompletedEvent event) async {
    if (!_ready ||
        !await settings.flag(SettingsRepository.keyCompletionNotifications)) {
      return;
    }
    final task = await store.loadTask(event.taskId);
    if (task == null) return;
    try {
      await _plugin.show(
        event.taskId.hashCode & 0x7fffffff,
        'Mediary · 下载完成',
        task.title,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'download_complete',
            '下载完成',
            channelDescription: '已完成的媒体下载',
            importance: Importance.defaultImportance,
            actions: [
              AndroidNotificationAction('play', '播放', showsUserInterface: true),
              AndroidNotificationAction(
                'share',
                '分享',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'download_complete',
          ),
          macOS: DarwinNotificationDetails(
            categoryIdentifier: 'download_complete',
          ),
          linux: LinuxNotificationDetails(),
          windows: WindowsNotificationDetails(),
        ),
        payload: event.taskId,
      );
    } catch (_) {
      /* platform may not support notifications */
    }
  }

  Future<void> _notifyDiskFull(String taskId) async {
    if (!_ready) return;
    final task = await store.loadTask(taskId);
    if (task == null) return;
    try {
      await _plugin.show(
        taskId.hashCode & 0x7fffffff,
        'Mediary · 磁盘空间不足',
        '${task.title}：下载已暂停，清理磁盘后可恢复',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'download_paused',
            '下载暂停',
            channelDescription: '需要用户处理的下载暂停',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
          linux: LinuxNotificationDetails(),
          windows: WindowsNotificationDetails(),
        ),
        payload: taskId,
      );
    } catch (_) {
      /* platform may not support notifications */
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
