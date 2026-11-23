#!/bin/zsh
# Apply schedule blocks from job-hunter.config.json to launchd.
# Usage: apply-schedule.sh [--dry-run]
#
# LinkedIn job search: schedules.linkedinJobSearch.times[] / .timezone
# Indeed (weekly phase):        schedules.indeedJobSearch.times[] / .timezone
# LinkedIn feed review:         schedules.linkedinFeedReview.times[] / .timezone
#                               empty times array = no job
# Report expiry:                common.reportExpiryHours / common.reportExpiryCheckMinutes
#                               runs .opencode/scripts/expire-reports.sh on an interval
set -u
setopt NULL_GLOB

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="${JOB_HUNTER_CONFIG:-$REPO/job-hunter.config.json}"
JOB_LABEL="ai.jobhunter.daily"
JOB_PLIST="${JOB_HUNTER_PLIST:-$HOME/Library/LaunchAgents/${JOB_LABEL}.plist}"
FEED_LABEL="ai.jobhunter.feedreview"
FEED_PLIST="${JOB_HUNTER_FEED_PLIST:-$HOME/Library/LaunchAgents/${FEED_LABEL}.plist}"
INDEED_LABEL="ai.jobhunter.indeed"
INDEED_PLIST="${JOB_HUNTER_INDEED_PLIST:-$HOME/Library/LaunchAgents/${INDEED_LABEL}.plist}"
EXPIRE_LABEL="ai.jobhunter.expire"
EXPIRE_PLIST="${JOB_HUNTER_EXPIRE_PLIST:-$HOME/Library/LaunchAgents/${EXPIRE_LABEL}.plist}"

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

if [ ! -r "$CONFIG" ]; then
  print -u2 -- "config not found: $CONFIG"
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  print -u2 -- "jq is required"
  exit 2
fi

sys_tz="$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')"
[ -n "$sys_tz" ] || sys_tz="$(date +%Z)"

typeset -ga TIMES
typeset -ga WEEKDAYS

validate_time() {
  case "$1" in
    [01][0-9]:[0-5][0-9]|2[0-3]:[0-5][0-9]) return 0 ;;
    *) return 1 ;;
  esac
}

check_timezone() {
  local tz="$1"
  [ -z "$tz" ] && return 0
  if [ "$tz" != "$sys_tz" ]; then
    print -u2 -- "schedule timezone is $tz but the system timezone is $sys_tz."
    print -u2 -- "launchd uses local time; change the system timezone or set the schedule timezone to $sys_tz."
    return 1
  fi
}

split_time() {
  HOUR="${1%%:*}"
  MINUTE="${1##*:}"
  HOUR="${HOUR#0}"; HOUR="${HOUR:-0}"
  MINUTE="${MINUTE#0}"; MINUTE="${MINUTE:-0}"
}

read_times() {
  local jq_path="$1" label="$2"
  local times_type t
  times_type="$(jq -r "($jq_path // []) | type" "$CONFIG")"
  if [ "$times_type" != "array" ]; then
    print -u2 -- "$label must be an array of HH:MM strings"
    return 1
  fi

  TIMES=()
  while IFS= read -r t; do
    [ -z "$t" ] && continue
    if ! validate_time "$t"; then
      print -u2 -- "$label must contain HH:MM (24h), got: $t"
      return 1
    fi
    TIMES+=("$t")
  done < <(jq -r "${jq_path}[]?" "$CONFIG")
}

# launchd Weekday values: 0 and 7 = Sunday, 1 = Monday ... 5 = Friday, 6 = Saturday.
# An empty array means every day (no Weekday key is written).
read_weekdays() {
  local jq_path="$1" label="$2"
  local days_type w
  days_type="$(jq -r "($jq_path // []) | type" "$CONFIG")"
  if [ "$days_type" != "array" ]; then
    print -u2 -- "$label must be an array of launchd weekdays (0-7)"
    return 1
  fi

  WEEKDAYS=()
  while IFS= read -r w; do
    [ -z "$w" ] && continue
    if [[ ! "$w" == [0-7] ]]; then
      print -u2 -- "$label must contain integers 0-7, got: $w"
      return 1
    fi
    WEEKDAYS+=("$w")
  done < <(jq -r "${jq_path}[]?" "$CONFIG")
}

emit_calendar_entries() {
  local t w
  if [ ${#WEEKDAYS[@]} -eq 0 ]; then
    for t in "${TIMES[@]}"; do
      split_time "$t"
      cat <<EOF
    <dict>
      <key>Hour</key>
      <integer>$HOUR</integer>
      <key>Minute</key>
      <integer>$MINUTE</integer>
    </dict>
EOF
    done
    return 0
  fi

  for t in "${TIMES[@]}"; do
    split_time "$t"
    for w in "${WEEKDAYS[@]}"; do
      cat <<EOF
    <dict>
      <key>Weekday</key>
      <integer>$w</integer>
      <key>Hour</key>
      <integer>$HOUR</integer>
      <key>Minute</key>
      <integer>$MINUTE</integer>
    </dict>
EOF
    done
  done
}

weekday_label() {
  if [ ${#WEEKDAYS[@]} -eq 0 ]; then
    print -r -- "every day"
  else
    print -r -- "weekdays ${(j:,:)WEEKDAYS}"
  fi
}

disable_job() {
  local label="$1" plist="$2" message="$3"
  if [ "$DRY_RUN" = "1" ]; then
    print -r -- "$message"
    return 0
  fi
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  rm -f "$plist"
  print -r -- "$message"
}

apply_job_search() {
  if [ "$(jq -r '(.schedules.linkedinJobSearch // null) != null' "$CONFIG")" != "true" ]; then
    disable_job "$JOB_LABEL" "$JOB_PLIST" "no schedules.linkedinJobSearch block; job search job disabled"
    return 0
  fi

  local tz
  tz="$(jq -r '.schedules.linkedinJobSearch.timezone // empty' "$CONFIG")"
  check_timezone "$tz" || return 1
  read_times '.schedules.linkedinJobSearch.times' 'schedules.linkedinJobSearch.times' || return 1
  read_weekdays '.schedules.linkedinJobSearch.weekdays' 'schedules.linkedinJobSearch.weekdays' || return 1

  if [ "$DRY_RUN" = "1" ]; then
    if [ ${#TIMES[@]} -eq 0 ]; then
      print -r -- "job search job: disabled (empty times), timezone=${tz:-system}, plist=$JOB_PLIST"
    else
      print -r -- "job search job: times=${(j:,:)TIMES}, $(weekday_label), timezone=${tz:-system}, plist=$JOB_PLIST"
    fi
    return 0
  fi

  if [ ${#TIMES[@]} -eq 0 ]; then
    disable_job "$JOB_LABEL" "$JOB_PLIST" "job search times empty; $JOB_LABEL unloaded and plist removed"
    return 0
  fi

  mkdir -p "$(dirname "$JOB_PLIST")"
  {
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$JOB_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$REPO/.opencode/scripts/daily-run.sh</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$REPO</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>JOB_HUNTER_PHASES</key>
    <string>linkedin</string>
  </dict>
  <key>StartCalendarInterval</key>
  <array>
EOF
    emit_calendar_entries
    cat <<EOF
  </array>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/jobhunter.launchd.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/jobhunter.launchd.err.log</string>
</dict>
</plist>
EOF
  } > "$JOB_PLIST"

  if ! plutil -lint "$JOB_PLIST" >/dev/null 2>&1; then
    print -u2 -- "generated plist is invalid: $JOB_PLIST"
    return 1
  fi

  launchctl bootout "gui/$(id -u)/$JOB_LABEL" 2>/dev/null || true
  if ! launchctl bootstrap "gui/$(id -u)" "$JOB_PLIST"; then
    print -u2 -- "launchctl bootstrap failed for $JOB_PLIST"
    return 1
  fi

  print -r -- "job search job applied: ${(j:,:)TIMES} $(weekday_label) (${tz:-system time}), label $JOB_LABEL"
}

apply_feed_review() {
  if [ "$(jq -r '(.schedules.linkedinFeedReview // null) != null' "$CONFIG")" != "true" ]; then
    disable_job "$FEED_LABEL" "$FEED_PLIST" "no schedules.linkedinFeedReview block; feed review job disabled"
    return 0
  fi

  local tz
  tz="$(jq -r '.schedules.linkedinFeedReview.timezone // .schedules.linkedinJobSearch.timezone // empty' "$CONFIG")"
  check_timezone "$tz" || return 1
  read_times '.schedules.linkedinFeedReview.times' 'schedules.linkedinFeedReview.times' || return 1
  read_weekdays '.schedules.linkedinFeedReview.weekdays' 'schedules.linkedinFeedReview.weekdays' || return 1

  if [ "$DRY_RUN" = "1" ]; then
    if [ ${#TIMES[@]} -eq 0 ]; then
      print -r -- "feed review job: disabled (empty times), timezone=${tz:-system}, plist=$FEED_PLIST"
    else
      print -r -- "feed review job: times=${(j:,:)TIMES}, $(weekday_label), timezone=${tz:-system}, plist=$FEED_PLIST"
    fi
    return 0
  fi

  if [ ${#TIMES[@]} -eq 0 ]; then
    disable_job "$FEED_LABEL" "$FEED_PLIST" "feed review times empty; $FEED_LABEL unloaded and plist removed"
    return 0
  fi

  mkdir -p "$(dirname "$FEED_PLIST")"
  {
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$FEED_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$REPO/.opencode/scripts/feed-review-run.sh</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$REPO</string>
  <key>StartCalendarInterval</key>
  <array>
EOF
    emit_calendar_entries
    cat <<EOF
  </array>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/jobhunter-feed-review.launchd.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/jobhunter-feed-review.launchd.err.log</string>
</dict>
</plist>
EOF
  } > "$FEED_PLIST"

  if ! plutil -lint "$FEED_PLIST" >/dev/null 2>&1; then
    print -u2 -- "generated plist is invalid: $FEED_PLIST"
    return 1
  fi

  launchctl bootout "gui/$(id -u)/$FEED_LABEL" 2>/dev/null || true
  if ! launchctl bootstrap "gui/$(id -u)" "$FEED_PLIST"; then
    print -u2 -- "launchctl bootstrap failed for $FEED_PLIST"
    return 1
  fi

  print -r -- "feed review job applied: ${(j:,:)TIMES} $(weekday_label) (${tz:-system time}), label $FEED_LABEL"
}

apply_indeed_search() {
  if [ "$(jq -r '(.schedules.indeedJobSearch // null) != null' "$CONFIG")" != "true" ]; then
    disable_job "$INDEED_LABEL" "$INDEED_PLIST" "no schedules.indeedJobSearch block; indeed job disabled"
    return 0
  fi

  local tz
  tz="$(jq -r '.schedules.indeedJobSearch.timezone // .schedules.linkedinJobSearch.timezone // empty' "$CONFIG")"
  check_timezone "$tz" || return 1
  read_times '.schedules.indeedJobSearch.times' 'schedules.indeedJobSearch.times' || return 1
  read_weekdays '.schedules.indeedJobSearch.weekdays' 'schedules.indeedJobSearch.weekdays' || return 1

  if [ "$DRY_RUN" = "1" ]; then
    if [ ${#TIMES[@]} -eq 0 ]; then
      print -r -- "indeed job: disabled (empty times), timezone=${tz:-system}, plist=$INDEED_PLIST"
    else
      print -r -- "indeed job: times=${(j:,:)TIMES}, $(weekday_label), timezone=${tz:-system}, plist=$INDEED_PLIST"
    fi
    return 0
  fi

  if [ ${#TIMES[@]} -eq 0 ]; then
    disable_job "$INDEED_LABEL" "$INDEED_PLIST" "indeed times empty; $INDEED_LABEL unloaded and plist removed"
    return 0
  fi

  mkdir -p "$(dirname "$INDEED_PLIST")"
  {
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$INDEED_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$REPO/.opencode/scripts/daily-run.sh</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$REPO</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>JOB_HUNTER_PHASES</key>
    <string>indeed</string>
  </dict>
  <key>StartCalendarInterval</key>
  <array>
EOF
    emit_calendar_entries
    cat <<EOF
  </array>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/jobhunter-indeed.launchd.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/jobhunter-indeed.launchd.err.log</string>
</dict>
</plist>
EOF
  } > "$INDEED_PLIST"

  if ! plutil -lint "$INDEED_PLIST" >/dev/null 2>&1; then
    print -u2 -- "generated plist is invalid: $INDEED_PLIST"
    return 1
  fi

  launchctl bootout "gui/$(id -u)/$INDEED_LABEL" 2>/dev/null || true
  if ! launchctl bootstrap "gui/$(id -u)" "$INDEED_PLIST"; then
    print -u2 -- "launchctl bootstrap failed for $INDEED_PLIST"
    return 1
  fi

  print -r -- "indeed job applied: ${(j:,:)TIMES} $(weekday_label) (${tz:-system time}), label $INDEED_LABEL"
}

apply_report_expiry() {
  local remote hours minutes interval
  remote="$(jq -r '.common.reportRepo // empty' "$CONFIG")"
  hours="$(jq -r '.common.reportExpiryHours // 0' "$CONFIG")"
  minutes="$(jq -r '.common.reportExpiryCheckMinutes // 15' "$CONFIG")"

  if [ -z "$remote" ]; then
    disable_job "$EXPIRE_LABEL" "$EXPIRE_PLIST" "no common.reportRepo; report expiry job disabled"
    return 0
  fi
  if ! [[ "$hours" =~ '^[0-9]+([.][0-9]+)?$' ]]; then
    print -u2 -- "common.reportExpiryHours must be a non-negative number, got: $hours"
    return 1
  fi
  if ! awk -v h="$hours" 'BEGIN { exit !(h > 0) }'; then
    disable_job "$EXPIRE_LABEL" "$EXPIRE_PLIST" "report expiry off (common.reportExpiryHours=$hours); $EXPIRE_LABEL unloaded and plist removed"
    return 0
  fi
  if ! [[ "$minutes" =~ '^[0-9]+$' ]] || [ "$minutes" -lt 1 ]; then
    print -u2 -- "common.reportExpiryCheckMinutes must be a positive integer, got: $minutes"
    return 1
  fi

  interval=$(( minutes * 60 ))

  if [ "$DRY_RUN" = "1" ]; then
    print -r -- "report expiry job: every ${minutes}m, expires published reports after ${hours}h, plist=$EXPIRE_PLIST"
    return 0
  fi

  mkdir -p "$(dirname "$EXPIRE_PLIST")"
  {
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$EXPIRE_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$REPO/.opencode/scripts/expire-reports.sh</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$REPO</string>
  <key>StartInterval</key>
  <integer>$interval</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/jobhunter-expire.launchd.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/jobhunter-expire.launchd.err.log</string>
</dict>
</plist>
EOF
  } > "$EXPIRE_PLIST"

  if ! plutil -lint "$EXPIRE_PLIST" >/dev/null 2>&1; then
    print -u2 -- "generated plist is invalid: $EXPIRE_PLIST"
    return 1
  fi

  launchctl bootout "gui/$(id -u)/$EXPIRE_LABEL" 2>/dev/null || true
  if ! launchctl bootstrap "gui/$(id -u)" "$EXPIRE_PLIST"; then
    print -u2 -- "launchctl bootstrap failed for $EXPIRE_PLIST"
    return 1
  fi

  print -r -- "report expiry job applied: every ${minutes}m, TTL ${hours}h, label $EXPIRE_LABEL"
}

rc=0
apply_job_search || rc=1
apply_indeed_search || rc=1
apply_feed_review || rc=1
apply_report_expiry || rc=1
exit $rc
