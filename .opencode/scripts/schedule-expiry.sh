#!/bin/zsh
# Schedule a ONE-SHOT cleanup of the published report repo.
#
# Instead of polling every N minutes, the publish step calls this script once:
# it writes a launchd job that fires exactly once at
#
#     publish_time + common.reportExpiryHours + margin
#
# and then removes itself. No idle timer, no repeated git fetch.
#
# Usage: schedule-expiry.sh [--delay <seconds>] [--at <epoch>] [--dry-run]
#   --delay N   fire N seconds from now (testing; overrides the TTL)
#   --at EPOCH  fire at an absolute epoch
#   --dry-run   print what would be scheduled, change nothing
#
# Env:
#   JOB_HUNTER_EXPIRY_MARGIN   extra seconds added to the TTL (default 90)
set -u
setopt NULL_GLOB

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="${JOB_HUNTER_CONFIG:-$REPO/job-hunter.config.json}"
LAUNCH_DIR="$HOME/Library/LaunchAgents"
LOG="${JOB_HUNTER_EXPIRE_LOG:-$HOME/Library/Logs/jobhunter-expire.log}"
MARGIN="${JOB_HUNTER_EXPIRY_MARGIN:-90}"
PREFIX="ai.jobhunter.expire.at"

DRY_RUN=0
DELAY=""
AT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --delay) DELAY="${2:-}"; shift 2 ;;
    --at) AT="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) print -u2 -- "unknown argument: $1"; exit 2 ;;
  esac
done

log() { print -r -- "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

if [ ! -r "$CONFIG" ]; then
  print -u2 -- "config not found: $CONFIG"
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  print -u2 -- "jq is required"
  exit 2
fi

REMOTE="$(jq -r '.common.reportRepo // empty' "$CONFIG")"
HOURS="$(jq -r '.common.reportExpiryHours // 0' "$CONFIG")"

[ -n "$REMOTE" ] || exit 0

now="$(date +%s)"
if [ -n "$AT" ]; then
  due="$AT"
elif [ -n "$DELAY" ]; then
  due=$(( now + DELAY ))
else
  if ! awk -v h="$HOURS" 'BEGIN { exit !(h > 0) }'; then
    exit 0
  fi
  due="$(awk -v n="$now" -v h="$HOURS" -v m="$MARGIN" 'BEGIN { printf "%d", n + h * 3600 + m }')"
fi

label="${PREFIX}${due}"
plist="$LAUNCH_DIR/${label}.plist"

# launchd calendar jobs are minute-granular: the margin keeps us off the
# minute that already started.
mo="$(date -r "$due" +%m)"
dy="$(date -r "$due" +%d)"
hr="$(date -r "$due" +%H)"
mi="$(date -r "$due" +%M)"
new="$(date -r "$due" '+%Y-%m-%d %H:%M')"

if [ "$DRY_RUN" = "1" ]; then
  print -r -- "would fire once at $new (TTL ${HOURS}h, margin ${MARGIN}s), label $label"
  exit 0
fi

# Drop one-shot jobs whose time has passed (crashed/aborted runs).
for old in "$LAUNCH_DIR/${PREFIX}"*.plist(N); do
  oldlabel="${${old:t}%.plist}"
  olddue="${oldlabel#${PREFIX}}"
  if [[ "$olddue" =~ '^[0-9]+$' ]] && [ "$olddue" -lt $(( now - 120 )) ]; then
    launchctl bootout "gui/$(id -u)/$oldlabel" >/dev/null 2>&1 || true
    rm -f "$old"
    log "removed stale one-shot $oldlabel"
  fi
done

CONFIG_ENV_BLOCK=""
if [ "${JOB_HUNTER_CONFIG:-}" != "" ]; then
  CONFIG_ENV_BLOCK="
  <key>EnvironmentVariables</key>
  <dict>
    <key>JOB_HUNTER_CONFIG</key>
    <string>$JOB_HUNTER_CONFIG</string>
  </dict>"
fi

mkdir -p "$LAUNCH_DIR"
cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$REPO/.opencode/scripts/run-expiry-once.sh</string>
    <string>$label</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$REPO</string>${CONFIG_ENV_BLOCK}
  <key>StartCalendarInterval</key>
  <dict>
    <key>Month</key><integer>$(( mo ))</integer>
    <key>Day</key><integer>$(( dy ))</integer>
    <key>Hour</key><integer>$(( hr ))</integer>
    <key>Minute</key><integer>$(( mi ))</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/jobhunter-expire.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/jobhunter-expire.err.log</string>
</dict>
</plist>
EOF

if ! plutil -lint "$plist" >/dev/null 2>&1; then
  print -u2 -- "generated plist is invalid: $plist"
  rm -f "$plist"
  exit 1
fi

launchctl bootout "gui/$(id -u)/$label" >/dev/null 2>&1 || true
if ! launchctl bootstrap "gui/$(id -u)" "$plist"; then
  print -u2 -- "launchctl bootstrap failed for $plist"
  exit 1
fi

log "scheduled one-shot $label at $new (TTL ${HOURS}h, margin ${MARGIN}s)"
print -r -- "scheduled $label at $new"
