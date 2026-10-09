import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Keeps the app alive when the main window is closed on desktop.
///
/// Closing the window hides it instead of quitting so downloads continue in
/// the background. On Windows a tray icon restores the window on left click
/// and natively pops up a right-click menu with "quit"; on macOS the app
/// simply stays in the Dock (clicking it reopens the window).
class DesktopWindowService with WindowListener {
  DesktopWindowService._();

  static final instance = DesktopWindowService._();

  /// Set once the user explicitly asks to quit (tray menu), so the close
  /// handler lets the window through instead of hiding it again.
  bool _quitting = false;

  /// Optional hook run before the process exits, used to cancel in-flight
  /// engine work (downloads, decrypt isolates) so teardown is not blocked
  /// waiting on them. Registered by the app layer, which owns the engine.
  Future<void> Function()? onBeforeQuit;

  TrayIcon? _trayIcon;

  // The nativeapi Image/Menu/MenuItem objects release their native handles
  // when garbage collected, so they must stay reachable for as long as the
  // tray icon lives — holding them here keeps the icon and menu alive.
  Image? _trayImage;
  Menu? _trayMenu;
  MenuItem? _quitItem;

  bool get isDesktop => Platform.isWindows || Platform.isMacOS;

  Future<void> initialize() async {
    if (!isDesktop) return;
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);

    if (Platform.isWindows) {
      await _initTray();
    }
  }

  /// Creates the Windows tray icon with a native right-click context menu.
  ///
  /// The menu is opened by the OS on right click (`contextMenuTrigger`),
  /// which works even while the main window is hidden — the legacy
  /// Dart-side `popUpContextMenu` path could not rely on that.
  Future<void> _initTray() async {
    final tray = TrayIcon.create();
    if (tray == null) return;
    _trayIcon = tray;

    _trayImage = ImageAsset.fromAsset('assets/tray_icon.ico');
    tray.icon = _trayImage;
    tray.setTooltip('Mediary');

    final menu = Menu.create();
    if (menu != null) {
      final quitItem = MenuItem.createWithLabelAndType(
        '退出 Mediary',
        MenuItemType.normal,
      );
      quitItem?.addListener((event) {
        // This callback runs synchronously inside the native menu's modal
        // loop (TrackPopupMenu). Disposing the menu/tray or tearing down the
        // window here would deadlock against the native side still using
        // them, so defer the quit until the callback returns.
        if (event is MenuItemClickedEvent) Timer.run(_quit);
      });
      menu.addItem(quitItem);
      tray.setContextMenu(menu);
      _trayMenu = menu;
      _quitItem = quitItem;
    }
    tray.setContextMenuTrigger(ContextMenuTrigger.rightClicked);

    // A left click restores the hidden window.
    tray.addListener((event) {
      if (event is TrayIconClickedEvent) showMainWindow();
    });
    tray.setVisible(true);
  }

  /// Restores and focuses the hidden main window.
  Future<void> showMainWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    if (_quitting) return;
    _quitting = true;

    // Hide the window immediately so the UI disappears the moment the user
    // clicks quit; the bounded teardown below then runs invisibly instead of
    // freezing a still-visible window.
    await windowManager.hide();

    // Stop in-flight engine work first (downloads, decrypt isolates, timers).
    // Without this the native teardown below blocks on those futures and the
    // window appears to hang for seconds after the tray icon is already gone.
    // Kept short: a hard exit is crash-safe (.part + atomic rename, sqlite
    // WAL), so there is no need to wait long for cancels to settle.
    final hook = onBeforeQuit;
    if (hook != null) {
      await hook().timeout(
        const Duration(milliseconds: 400),
        onTimeout: () {},
      );
    }

    _trayIcon?.dispose();
    _trayIcon = null;
    _trayMenu?.dispose();
    _trayMenu = null;
    _quitItem?.dispose();
    _quitItem = null;
    _trayImage?.dispose();
    _trayImage = null;

    // Kick off the native window teardown, but do not await it: destroy()
    // resolves over a MethodChannel whose engine may already be tearing down,
    // so the future can hang indefinitely. Instead race it against a hard
    // process exit — whichever lands first wins, and exit(0) guarantees the
    // process actually terminates. Downloads use .part + atomic rename and
    // sqlite runs in WAL mode, so a hard exit here is crash-safe.
    unawaited(
      windowManager.destroy().timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    exit(0);
  }

  @override
  void onWindowClose() {
    if (_quitting || !isDesktop) return;
    // Hide instead of closing; downloads keep running in the background.
    windowManager.hide();
  }
}
