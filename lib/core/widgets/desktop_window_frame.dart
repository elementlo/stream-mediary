import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Height of the in-app draggable title bar on immersive desktop platforms.
///
/// macOS reserves ~28px for the traffic lights; Windows uses the standard
/// 32px caption height so the self-drawn caption buttons match the OS metric.
/// Returns 0 on Linux/mobile, which keep their native window chrome.
double immersiveTitleBarHeight() {
  if (Platform.isMacOS) return 28;
  if (Platform.isWindows) return 32;
  return 0;
}

/// Whether the app draws its own title bar (immersive) on this platform.
bool get isImmersiveDesktop => Platform.isMacOS || Platform.isWindows;

/// Wraps the app body on macOS/Windows to provide an immersive title bar:
/// a transparent draggable strip along the top edge plus (on Windows) the
/// minimize/maximize/close caption buttons, since `TitleBarStyle.hidden`
/// removes the native ones there. macOS keeps its native traffic lights,
/// which float above this strip.
///
/// On Linux and mobile this is a pass-through — those platforms keep their
/// native window chrome.
///
/// The strip overlays content rather than occupying layout space, so page
/// backgrounds (e.g. the navigation rail) still extend to the very top of
/// the window. Content that would collide with the strip or the native
/// controls pads itself using [immersiveTitleBarHeight] / [trafficLightInset].
class DesktopWindowFrame extends StatefulWidget {
  const DesktopWindowFrame({super.key, required this.child});

  final Widget child;

  @override
  State<DesktopWindowFrame> createState() => _DesktopWindowFrameState();
}

class _DesktopWindowFrameState extends State<DesktopWindowFrame>
    with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    if (isImmersiveDesktop) {
      windowManager.addListener(this);
      // Seed the maximize/restore icon with the current window state.
      windowManager.isMaximized().then((value) {
        if (mounted && value != _maximized) setState(() => _maximized = value);
      });
    }
  }

  @override
  void dispose() {
    if (isImmersiveDesktop) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  Widget build(BuildContext context) {
    if (!isImmersiveDesktop) return widget.child;

    final height = immersiveTitleBarHeight();
    // Reserve the title-bar height as top "safe area" so AppBar-based pages
    // (e.g. the player) automatically push their content below the strip —
    // an AppBar grows to absorb MediaQuery.padding.top and paints its
    // background up into it, so no seam appears. Widgets that do not consume
    // MediaQuery (the navigation rail, the desktop title row) pad themselves
    // explicitly instead, keeping their backgrounds flush with the window top.
    final media = MediaQuery.of(context);
    final padded = MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(top: media.padding.top + height),
      ),
      child: widget.child,
    );

    return Stack(
      children: [
        padded,
        // Draggable strip along the top. Translucent hit-testing lets the
        // native macOS traffic lights (which sit above the Flutter view)
        // stay clickable, while empty strip area drags the window.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height,
          child: DragToMoveArea(child: const SizedBox.expand()),
        ),
        // Windows loses its native caption buttons under TitleBarStyle.hidden,
        // so draw them. macOS keeps the traffic lights and needs nothing here.
        if (Platform.isWindows)
          Positioned(
            top: 0,
            right: 0,
            height: height,
            child: _WindowsCaptionButtons(maximized: _maximized),
          ),
      ],
    );
  }
}

/// Self-drawn minimize / maximize-restore / close buttons for Windows.
class _WindowsCaptionButtons extends StatelessWidget {
  const _WindowsCaptionButtons({required this.maximized});

  final bool maximized;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        WindowCaptionButton.minimize(
          brightness: brightness,
          onPressed: () => windowManager.minimize(),
        ),
        if (maximized)
          WindowCaptionButton.unmaximize(
            brightness: brightness,
            onPressed: () => windowManager.unmaximize(),
          )
        else
          WindowCaptionButton.maximize(
            brightness: brightness,
            onPressed: () => windowManager.maximize(),
          ),
        WindowCaptionButton.close(
          brightness: brightness,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}
