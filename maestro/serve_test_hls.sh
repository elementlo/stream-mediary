#!/usr/bin/env bash
#
# Generates a small deterministic HLS stream (10s testsrc, 2s segments) and
# serves it on :8099 for Maestro download tests.
#
# Usage:
#   ./maestro/serve_test_hls.sh          # generate (if needed) + serve in foreground
#   ./maestro/serve_test_hls.sh --regen  # force regenerate segments
#
# Android device reaches it at http://<Mac-LAN-IP>:8099/index.m3u8
# iOS simulator reaches it at http://127.0.0.1:8099/index.m3u8
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)/test_hls"
PORT=8099

if [[ "${1:-}" == "--regen" ]] || [[ ! -f "$DIR/index.m3u8" ]]; then
  echo "==> Generating test HLS into $DIR ..."
  rm -rf "$DIR"
  mkdir -p "$DIR"
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "testsrc2=size=640x360:rate=25:duration=10" \
    -f lavfi -i "sine=frequency=440:duration=10" \
    -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a aac \
    -hls_time 2 -hls_list_size 0 -hls_segment_filename "$DIR/seg%d.ts" \
    "$DIR/index.m3u8"
  echo "==> Generated: $(ls "$DIR" | tr '\n' ' ')"
fi

echo "==> Serving $DIR on :$PORT (Ctrl-C to stop)"
cd "$DIR"
exec python3 -m http.server "$PORT" --bind 0.0.0.0
