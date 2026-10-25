#!/bin/bash
# Records the example app's capture mode on an iOS simulator and cuts one
# GIF per screen into doc/gifs/. Needs a booted simulator, dn and ffmpeg.
#
#   tool/make_gifs.sh [simulator-udid]
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd)
UDID=${1:-$(xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1)}
WORK=$(mktemp -d)
OUT="$ROOT/doc/gifs"
mkdir -p "$OUT"

echo "Simulator: $UDID"

# Build and launch in capture mode.
(cd example_app && exec dn run -d "$UDID" --dart-define=CAPTURE=true > "$WORK/run.log" 2>&1) &
RUN_PID=$!
for _ in $(seq 1 600); do
  if grep -q "Dart VM Service" "$WORK/run.log" 2>/dev/null; then break; fi
  sleep 0.5
done
echo "App running; recording."
xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$WORK/capture.mp4" > "$WORK/rec.log" 2>&1 &
REC_PID=$!
# The video's first frame is when simctl reports that recording started.
for _ in $(seq 1 200); do
  if grep -q "Recording started" "$WORK/rec.log"; then break; fi
  sleep 0.05
done
START_MS=$(python3 -c 'import time; print(int(time.time()*1000))')

# Wait for the app to play every screen.
for _ in $(seq 1 900); do
  if grep -q "CAPTURE_DONE" "$WORK/run.log"; then break; fi
  sleep 1
done
sleep 1
kill -INT $REC_PID; wait $REC_PID 2>/dev/null || true
kill $RUN_PID 2>/dev/null || true
grep -o "CAPTURE_TIMELINE .*" "$WORK/run.log" | cut -d' ' -f2- > "$WORK/timeline.txt"
echo "$(grep -c . "$WORK/timeline.txt") screens recorded."

# Cut each screen (skipping the push), at 20 fps, 320 px wide, with a
# palette per GIF for clean colors.
while read -r NAME S E; do
  SS=$(python3 -c "print(max(0, ($S - $START_MS) / 1000 + 0.35))")
  T=$(python3 -c "print(($E - $S) / 1000 - 0.45)")
  ffmpeg -nostdin -loglevel error -y -ss "$SS" -t "$T" -i "$WORK/capture.mp4" \
    -vf "fps=20,scale=320:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4" \
    "$OUT/$NAME.gif"
  echo "  $OUT/$NAME.gif"
done < "$WORK/timeline.txt"
echo "Done."
