#!/usr/bin/env bash
#
# Capture a home-page screenshot of Mediary on a DESKTOP platform.
#
# Why a separate script? Neither `integration_test`'s takeScreenshot() nor
# `flutter screenshot` support desktop. The macOS path renders the frame
# inside the engine via the VM service `_flutter.screenshot` extension, so it
# needs NO macOS screen-recording permission (screencapture / ScreenCaptureKit
# both fail without it, and Impeller cannot be captured — so we disable it).
#
# Usage:
#   ./tool/screenshot_desktop.sh macos [light|dark]   # default: light
#
# The app is built with SCREENSHOT_DEMO=true (seeds a live demo download,
# forces zh locale) and SCREENSHOT_THEME=<theme>.
#
# Output: docs/screenshots/macos-home-<theme>.png
set -euo pipefail

PLATFORM="${1:-macos}"
THEME="${2:-light}"
OUT_DIR="docs/screenshots"
OUT_FILE="$OUT_DIR/$PLATFORM-home-$THEME.png"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "$PLATFORM" != "macos" ]]; then
  echo "!! Only macos is supported here; Windows uses .github/workflows/windows-screenshot.yml" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "==> Building Mediary (macOS debug, theme=$THEME)..."
flutter build macos --debug \
  --dart-define=SCREENSHOT_DEMO=true \
  --dart-define=SCREENSHOT_THEME="$THEME"

APP="build/macos/Build/Products/Debug/Mediary.app"
PLIST="$APP/Contents/Info.plist"
BIN="$APP/Contents/MacOS/Mediary"

# Impeller frames cannot be captured via the VM service; fall back to Skia.
if /usr/libexec/PlistBuddy -c "Print :FLTEnableImpeller" "$PLIST" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Set :FLTEnableImpeller false" "$PLIST"
else
  /usr/libexec/PlistBuddy -c "Add :FLTEnableImpeller bool false" "$PLIST"
fi

echo "==> Launching app..."
pkill -f "Mediary.app/Contents/MacOS/Mediary" 2>/dev/null || true
sleep 1
RUN_LOG="$(mktemp)"
"$BIN" >"$RUN_LOG" 2>&1 &
RUN_PID=$!

cleanup() {
  kill "$RUN_PID" 2>/dev/null || true
  rm -f "$RUN_LOG"
}
trap cleanup EXIT

# Wait for the VM service URL to be printed.
VM_URL=""
for _ in $(seq 1 60); do
  VM_URL="$(grep -oE "http://127.0.0.1:[0-9]+/[A-Za-z0-9_=-]+/" "$RUN_LOG" | head -1 || true)"
  [[ -n "$VM_URL" ]] && break
  sleep 1
done
if [[ -z "$VM_URL" ]]; then
  echo "!! VM service URL did not appear." >&2
  cat "$RUN_LOG" >&2
  exit 1
fi
echo "    VM service: $VM_URL"

# Let the first frame and the demo task fully settle (debug JIT is slow).
sleep 12

echo "==> Capturing via VM service..."
python3 "$SCRIPT_DIR/vm_screenshot.py" "$VM_URL" "$OUT_FILE"

if [[ -f "$OUT_FILE" ]]; then
  echo "==> Done: $OUT_FILE"
else
  echo "!! Screenshot was not produced." >&2
  exit 1
fi
