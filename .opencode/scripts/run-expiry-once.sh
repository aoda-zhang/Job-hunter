#!/bin/zsh
# One-shot runner for the published-report cleanup.
#
# Called by the launchd job that schedule-expiry.sh created at
# publish_time + reportExpiryHours. It removes its own launchd job first (so it
# never fires twice), then runs expire-reports.sh. If the unit is not quite old
# enough yet (clock skew), it retries a few times before giving up.
#
# Usage: run-expiry-once.sh ai.jobhunter.expire.at<epoch>
#
# Env:
#   JOB_HUNTER_EXPIRE_DRYRUN=1   pass --dry-run to expire-reports.sh
set -u
setopt NULL_GLOB

PREFIX="ai.jobhunter.expire.at"
LABEL="${1:-}"
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
LAUNCH_DIR="$HOME/Library/LaunchAgents"
LOG="${JOB_HUNTER_EXPIRE_LOG:-$HOME/Library/Logs/jobhunter-expire.log}"
RETRIES="${JOB_HUNTER_EXPIRE_RETRIES:-5}"
RETRY_SLEEP="${JOB_HUNTER_EXPIRE_RETRY_SLEEP:-120}"

log() { print -r -- "$(date '+%Y-%m-%d %H:%M:%S') [once] $*" >> "$LOG"; }

case "$LABEL" in
  ${PREFIX}[0-9]*) ;;
  *) log "refusing unknown label: ${LABEL:-<empty>}"; exit 2 ;;
esac

plist="$LAUNCH_DIR/${LABEL}.plist"

# launchd tears down the whole process group when the main process exits, so the
# removal has to happen inline (trap), not in a background subshell.
cleanup_self() {
  rm -f "$plist"
  launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
}
trap cleanup_self EXIT INT TERM HUP

args=()
if [ "${JOB_HUNTER_EXPIRE_DRYRUN:-0}" = "1" ]; then
  args+=(--dry-run)
  RETRIES=1
fi

attempt=0
while true; do
  attempt=$(( attempt + 1 ))
  out="$("$REPO/.opencode/scripts/expire-reports.sh" "${args[@]}" 2>&1)"
  rc=$?
  print -r -- "$out" >> "$LOG"

  if [ "$rc" -ne 0 ]; then
    log "$LABEL: expire-reports.sh failed (rc=$rc), attempt $attempt"
    exit "$rc"
  fi
  if [[ "$out" == *"no published unit older than"* ]]; then
    if [ "$attempt" -ge "$RETRIES" ]; then
      log "$LABEL: nothing expired after $attempt attempt(s); giving up"
      exit 0
    fi
    sleep "$RETRY_SLEEP"
    continue
  fi
  log "$LABEL: done on attempt $attempt"
  exit 0
done
