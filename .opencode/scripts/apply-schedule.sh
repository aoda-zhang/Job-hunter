#!/bin/zsh
# Apply the schedule block from job-hunter.config.json to launchd.
# Usage: apply-schedule.sh [--dry-run]
set -u
setopt NULL_GLOB

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="${JOB_HUNTER_CONFIG:-$REPO/job-hunter.config.json}"
PLIST="${JOB_HUNTER_PLIST:-$HOME/Library/LaunchAgents/ai.jobhunter.daily.plist}"
LABEL="ai.jobhunter.daily"

if [ ! -r "$CONFIG" ]; then
  print -u2 -- "config not found: $CONFIG"
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  print -u2 -- "jq is required"
  exit 2
fi

if [ "$(jq -r 'has("schedule")' "$CONFIG")" != "true" ]; then
  print -r -- "no schedule block in $CONFIG; launchd left unchanged"
  exit 0
fi

enabled="$(jq -r '.schedule.enabled // false' "$CONFIG")"
time="$(jq -r '.schedule.time // "18:10"' "$CONFIG")"
tz="$(jq -r '.schedule.timezone // empty' "$CONFIG")"

case "$time" in
  [01][0-9]:[0-5][0-9]|2[0-3]:[0-5][0-9]) ;;
  *)
    print -u2 -- "schedule.time must be HH:MM (24h), got: $time"
    exit 2
    ;;
esac

hour="${time%%:*}"
minute="${time##*:}"
hour="${hour#0}"; hour="${hour:-0}"
minute="${minute#0}"; minute="${minute:-0}"

if [ -n "$tz" ]; then
  sys_tz="$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')"
  [ -n "$sys_tz" ] || sys_tz="$(date +%Z)"
  if [ "$tz" != "$sys_tz" ]; then
    print -u2 -- "schedule.timezone is $tz but the system timezone is $sys_tz."
    print -u2 -- "launchd uses local time; change the system timezone or set schedule.timezone to $sys_tz."
    exit 2
  fi
fi

if [ "${1:-}" = "--dry-run" ]; then
  print -r -- "schedule enabled=$enabled time=$time timezone=${tz:-system} plist=$PLIST"
  exit 0
fi

if [ "$enabled" != "true" ]; then
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  rm -f "$PLIST"
  print -r -- "schedule disabled; $LABEL unloaded and plist removed"
  exit 0
fi

mkdir -p "$(dirname "$PLIST")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$REPO/.opencode/scripts/daily-run.sh</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$REPO</string>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>$hour</integer>
    <key>Minute</key>
    <integer>$minute</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/jobhunter.launchd.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/jobhunter.launchd.err.log</string>
</dict>
</plist>
EOF

if ! plutil -lint "$PLIST" >/dev/null 2>&1; then
  print -u2 -- "generated plist is invalid: $PLIST"
  exit 2
fi

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
if ! launchctl bootstrap "gui/$(id -u)" "$PLIST"; then
  print -u2 -- "launchctl bootstrap failed for $PLIST"
  exit 2
fi

print -r -- "schedule applied: daily $time (${tz:-system time}), label $LABEL"
