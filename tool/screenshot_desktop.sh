#!/usr/bin/env bash
#
# Capture a home-page screenshot of Mediary on a DESKTOP platform.
#
# Why a separate script? Neither `integration_test`'s takeScreenshot() nor
# `flutter screenshot` support desktop. Instead we launch the app and capture
# its window with OS-level tooling:
#   - macOS:   osascript (window bounds) + screencapture -R (region capture)
#   - Windows: PowerShell CopyFromScreen (full screen; crop manually if needed)
#
# Usage:
#   ./tool/screenshot_desktop.sh macos
#   ./tool/screenshot_desktop.sh windows   # must run ON Windows (git-bash)
#
# Output: docs/screenshots/<platform>-home.png
set -euo pipefail

PLATFORM="${1:-macos}"
OUT_DIR="docs/screenshots"
OUT_FILE="$OUT_DIR/$PLATFORM-home.png"

mkdir -p "$OUT_DIR"

echo "==> Building & launching Mediary on $PLATFORM (debug)..."
RUN_LOG="$(mktemp)"
flutter run -d "$PLATFORM" --debug >"$RUN_LOG" 2>&1 &
RUN_PID=$!

echo "==> Waiting for app to start..."
for _ in $(seq 1 180); do
  if grep -q "Flutter run key commands" "$RUN_LOG" 2>/dev/null; then
    break
  fi
  sleep 1
done
sleep 4  # let the first frame fully settle

case "$PLATFORM" in
  macos)
    echo "==> Capturing app window via screencapture..."
    osascript -e 'tell application "System Events" to set frontmost of process "Mediary" to true' >/dev/null 2>&1 || true
    sleep 1
    BOUNDS="$(osascript -e 'tell application "System Events" to tell process "Mediary" to get {position, size} of window 1' 2>/dev/null | tr -d ' ')"
    if [[ -z "$BOUNDS" ]]; then
      echo "!! Could not read Mediary window bounds." >&2
      kill "$RUN_PID" 2>/dev/null || true; rm -f "$RUN_LOG"; exit 1
    fi
    echo "    window bounds: $BOUNDS"
    screencapture -x -R"$BOUNDS" "$OUT_FILE"
    ;;
  windows)
    echo "==> Capturing primary screen via PowerShell..."
    powershell.exe -NoProfile -Command "
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing;
      \$b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds;
      \$img=New-Object System.Drawing.Bitmap \$b.Width,\$b.Height;
      \$g=[System.Drawing.Graphics]::FromImage(\$img);
      \$g.CopyFromScreen(\$b.Location,[System.Drawing.Point]::Empty,\$b.Size);
      \$img.Save('$OUT_FILE');
    "
    ;;
  *)
    echo "!! Unsupported platform: $PLATFORM" >&2
    kill "$RUN_PID" 2>/dev/null || true; rm -f "$RUN_LOG"; exit 1
    ;;
esac

# Quit the running app.
kill "$RUN_PID" 2>/dev/null || true
rm -f "$RUN_LOG"

if [[ -f "$OUT_FILE" ]]; then
  echo "==> Done: $OUT_FILE"
else
  echo "!! Screenshot was not produced." >&2
  exit 1
fi
