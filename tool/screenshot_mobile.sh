#!/usr/bin/env bash
#
# Capture home-page screenshots (light + dark) on MOBILE platforms.
#
# Why OS-level capture? `integration_test`'s takeScreenshot() hangs on some
# emulators/GPUs (surface conversion never completes — see
# docs/blog-flutter-desktop-screenshots.md). `adb exec-out screencap` and
# `xcrun simctl io screenshot` are deterministic and need no test harness.
#
# The app is built with SCREENSHOT_DEMO=true (seeds a live demo download,
# forces zh locale, freezes pulse animations) and SCREENSHOT_THEME=<theme>.
#
# Usage:
#   ./tool/screenshot_mobile.sh android [device-id]   # default emulator-5554
#   ./tool/screenshot_mobile.sh ios [device-id]       # default the Pixel/iPhone sim below
#
# Output: docs/screenshots/<platform>-home-light.png / -home-dark.png
set -euo pipefail

PLATFORM="${1:-android}"
OUT_DIR="docs/screenshots"
mkdir -p "$OUT_DIR"

case "$PLATFORM" in
  android)
    DEVICE="${2:-emulator-5554}"
    PKG="com.element.stream_mediary"
    for THEME in light dark; do
      echo "==> Building APK ($THEME)..."
      flutter build apk --debug \
        --dart-define=SCREENSHOT_DEMO=true \
        --dart-define=SCREENSHOT_THEME="$THEME"
      adb -s "$DEVICE" install -r build/app/outputs/flutter-apk/app-debug.apk
      adb -s "$DEVICE" shell am force-stop "$PKG"
      adb -s "$DEVICE" shell am start -n "$PKG/.MainActivity" >/dev/null
      echo "==> Waiting for first frame (debug JIT is slow)..."
      sleep 20
      adb -s "$DEVICE" exec-out screencap -p > "$OUT_DIR/android-home-$THEME.png"
      echo "==> Saved $OUT_DIR/android-home-$THEME.png"
    done
    ;;
  ios)
    DEVICE="${2:-D1D7CA22-82C5-4906-87CE-BEC46EF72CF6}"
    PKG="com.element.streamMediary"
    for THEME in light dark; do
      echo "==> Building iOS simulator app ($THEME)..."
      flutter build ios --debug --simulator \
        --dart-define=SCREENSHOT_DEMO=true \
        --dart-define=SCREENSHOT_THEME="$THEME"
      xcrun simctl install "$DEVICE" build/ios/iphonesimulator/Runner.app
      xcrun simctl terminate "$DEVICE" "$PKG" 2>/dev/null || true
      xcrun simctl launch "$DEVICE" "$PKG" >/dev/null
      echo "==> Waiting for first frame..."
      sleep 15
      xcrun simctl io "$DEVICE" screenshot "$OUT_DIR/ios-home-$THEME.png"
      echo "==> Saved $OUT_DIR/ios-home-$THEME.png"
    done
    ;;
  *)
    echo "!! Unsupported platform: $PLATFORM (use android|ios; desktop: screenshot_desktop.sh)" >&2
    exit 1
    ;;
esac
