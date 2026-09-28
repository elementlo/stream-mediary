import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Keeps the app alive when the main window is closed on desktop.
///
/// Closing the window hides it instead of quitting so downloads continue in
/// the background. On Windows a tray icon offers "show" and "quit"; on macOS
/// the app simply stays in the Dock (clicking it reopens the window).
class DesktopWindowService with WindowListener, TrayListener {
  DesktopWindowService._();

  static final instance = DesktopWindowService._();

  /// Set once the user explicitly asks to quit (tray menu), so the close
  /// handler lets the window through instead of hiding it again.
  bool _quitting = false;

  bool get isDesktop => Platform.isWindows || Platform.isMacOS;

  Future<void> initialize() async {
    if (!isDesktop) return;
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);

    if (Platform.isWindows) {
      await trayManager.setIcon('assets/tray_icon.ico');
      await trayManager.setToolTip('Mediary');
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(key: 'show', label: '显示主界面'),
            MenuItem.separator(),
            MenuItem(key: 'quit', label: '退出 Mediary'),
          ],
        ),
      );
      trayManager.addListener(this);
    }
  }

  /// Restores and focuses the hidden main window.
  Future<void> showMainWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    _quitting = true;
    if (Platform.isWindows) {
      await trayManager.destroy();
    }
    // destroy() bypasses the close interception and terminates the app.
    await windowManager.destroy();
  }

  @override
  void onWindowClose() {
    if (_quitting || !isDesktop) return;
    // Hide instead of closing; downloads keep running in the background.
    windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    // Windows: a left click on the tray icon restores the window.
    showMainWindow();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        showMainWindow();
      case 'quit':
        _quit();
    }
  }
}
