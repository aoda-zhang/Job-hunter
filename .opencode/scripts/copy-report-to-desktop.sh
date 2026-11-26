#!/bin/zsh
# Copy one job-search run folder to the Desktop as a readable snapshot.
#
# Usage: copy-report-to-desktop.sh <run-folder>
#
# Controlled by common.report.desktopCopy in job-hunter.config.json:
#   enabled   - false by default
#   afterHour - only runs whose folder timestamp starts at/after this hour (default 18)
#   directory - destination root (default ~/Desktop)
#
# Only report artifacts are copied: every non-hidden file in the run folder
# (*.md, *.pdf, per-vacancy fields.json / cover-letter.json). Hidden scratch
# helpers and reports/runs, reports/applications are never copied.
set -u
setopt NULL_GLOB

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="$REPO/job-hunter.config.json"
RUN_DIR="${1:-}"

if [ -z "$RUN_DIR" ]; then
  print -u2 -- "usage: copy-report-to-desktop.sh <run-folder>"
  exit 2
fi

case "$RUN_DIR" in
  /*) ;;
  *) RUN_DIR="$REPO/$RUN_DIR" ;;
esac

if [ ! -d "$RUN_DIR" ]; then
  print -u2 -- "desktop copy: run folder not found: $RUN_DIR"
  exit 1
fi

if [ ! -f "$CONFIG" ]; then
  print -u2 -- "desktop copy: config not found: $CONFIG"
  exit 1
fi

# jq is present on macOS; fall back to python3 if it is ever missing.
read_config() {
  local key="$1" fallback="$2"
  if command -v jq >/dev/null 2>&1; then
    jq -r "$key // \"$fallback\"" "$CONFIG" 2>/dev/null
  else
    python3 - "$CONFIG" "$key" "$fallback" <<'PY'
import json, sys
path, key, fallback = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    value = json.load(open(path))
    for part in key.strip('.').split('.'):
        value = value[part]
except Exception:
    value = fallback
print(fallback if value is None else value)
PY
  fi
}

enabled="$(read_config '.common.report.desktopCopy.enabled' 'false')"
after_hour="$(read_config '.common.report.desktopCopy.afterHour' '18')"
dest_root="$(read_config '.common.report.desktopCopy.directory' '~/Desktop')"

if [ "$enabled" != "true" ]; then
  print -r -- "desktop copy: disabled"
  exit 0
fi

case "$after_hour" in
  ''|*[!0-9]*) after_hour=18 ;;
esac

# The run folder name is the run start time: YYYY-MM-DD-HHMM or ...-HHMM-2.
base="${RUN_DIR:t}"
hour=""
if [[ "$base" =~ '-([0-9]{2})([0-9]{2})(-[0-9]+)?$' ]]; then
  hour="${match[1]}"
else
  hour="$(date +%H)"
fi

if (( 10#$hour < 10#$after_hour )); then
  print -r -- "desktop copy: run started before ${after_hour}:00, skipped"
  exit 0
fi

# Expand a leading ~ only; other paths are used as given.
case "$dest_root" in
  "~") dest_root="$HOME" ;;
  "~/"*) dest_root="$HOME/${dest_root#\~/}" ;;
esac

if [ ! -d "$dest_root" ]; then
  print -u2 -- "desktop copy: destination not found: $dest_root"
  exit 1
fi

target="$dest_root/JobHunter-$base"
tmp="$target.tmp.$$"
rm -rf "$tmp"
mkdir -p "$tmp" || exit 1

copied=0
for f in "$RUN_DIR"/**/*(.N); do
  rel="${f#"$RUN_DIR"/}"
  mkdir -p "$tmp/${rel:h}" || { rm -rf "$tmp"; exit 1; }
  cp -p "$f" "$tmp/$rel" || { rm -rf "$tmp"; exit 1; }
  copied=$((copied + 1))
done

if [ "$copied" -eq 0 ]; then
  rm -rf "$tmp"
  print -u2 -- "desktop copy: no report files in $RUN_DIR"
  exit 1
fi

# Never delete an existing Desktop snapshot: macOS TCC may deny removing a
# folder that another process created, and `mv tmp target` would then nest the
# copy inside it. The run folder name is unique, so a second copy is a no-op.
if [ -e "$target" ]; then
  rm -rf "$tmp" 2>/dev/null || true
  print -r -- "desktop copy: $target already exists, left unchanged"
  exit 0
fi

mv "$tmp" "$target" || { rm -rf "$tmp" 2>/dev/null || true; exit 1; }
print -r -- "desktop copy: $target ($copied report file(s))"
exit 0
