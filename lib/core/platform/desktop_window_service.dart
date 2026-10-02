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
    _quitting = true;
    _trayIcon?.dispose();
    _trayIcon = null;
    _trayMenu?.dispose();
    _trayMenu = null;
    _quitItem?.dispose();
    _quitItem = null;
    _trayImage?.dispose();
    _trayImage = null;
    // destroy() bypasses the close interception and terminates the app.
    await windowManager.destroy();
  }

  @override
  void onWindowClose() {
    if (_quitting || !isDesktop) return;
    // Hide instead of closing; downloads keep running in the background.
    windowManager.hide();
  }
}
