#!/bin/zsh
# Daily Job Hunter run, intended for launchd.
# Runs each source in its own OpenCode session, in `sources` order, to keep
# every session small: LinkedIn (discovery + apply + feed jobs), then Indeed.
set -u
setopt NULL_GLOB

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
export PATH="$HOME/Library/pnpm/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
for d in "$HOME"/.nvm/versions/node/*/bin; do PATH="$d:$PATH"; done
export PATH
export LANG="${LANG:-en_US.UTF-8}"

# Keep the system awake while this run is active.
# This cannot wake a Mac that is already asleep; it only prevents sleep during the run.
caffeinate -i -s -w $$ >/dev/null 2>&1 &

LOG="$HOME/Library/Logs/jobhunter.log"
MODEL="${JOB_HUNTER_MODEL:-deepseek/deepseek-flash}"
PHASES="${JOB_HUNTER_PHASES:-linkedin,indeed}"
mkdir -p "$HOME/Library/Logs" "$REPO/reports/runs"

cd "$REPO" || { print -r -- "$(date) repo unavailable: $REPO" >> "$LOG"; exit 1; }

# Single-instance lock: a second daily run must never drive the same browser.
LOCK="$REPO/reports/runs/.daily-run.lock"
if [ -f "$LOCK" ]; then
  holder="$(cat "$LOCK" 2>/dev/null)"
  if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
    print -r -- "=== $(date) start refused: daily run already active (pid $holder) ===" >> "$LOG"
    exit 3
  fi
  print -r -- "=== $(date) stale lock removed (pid ${holder:-unknown}) ===" >> "$LOG"
  rm -f "$LOCK"
fi
print -r -- "$$" > "$LOCK"
trap 'rm -f "$LOCK"' EXIT INT TERM HUP
print -r -- "=== $(date) lock acquired (pid $$) ===" >> "$LOG"

# The browse extension needs Chrome; bring it up quietly if it is closed.
if ! pgrep -x "Google Chrome" >/dev/null 2>&1; then
  open -g -a "Google Chrome"
  sleep 8
fi

run_phase() {
  local phase="$1"
  local prompt="$2"
  local title="$3"
  if [[ ",$PHASES," != *",$phase,"* ]]; then
    print -r -- "=== $(date) phase $phase skipped (JOB_HUNTER_PHASES=$PHASES) ===" >> "$LOG"
    return 0
  fi
  print -r -- "=== $(date) phase $phase start ===" >> "$LOG"
  opencode run \
    --agent job-hunter \
    --model "$MODEL" \
    --auto \
    --archived \
    --title "$title $(date +%F)" \
    "$prompt" \
    >> "$LOG" 2>&1
  local code=$?
  print -r -- "=== $(date) phase $phase exit $code ===" >> "$LOG"
  return $code
}

STOP_RULE="If any platform shows a trust signal — verify you are human, CAPTCHA, unusual activity, automated access, are you a robot, an AI-agent warning, or a forced re-login/2FA — stop the entire run immediately, submit nothing further, report the exact dialog text and hand control back."

SERIAL_RULE="Work strictly sequentially: one query at a time, one posting at a time, one tab at a time. Finish a job (open, read, classify, apply or inspect, record, close) before opening the next. Never batch-open job cards or job URLs, never loop over several job IDs in one tool call, and never run browser actions in parallel."

LINKEDIN_PROMPT="Run today's job-search pass for LinkedIn only. Load job-discovery and follow it exactly, scoping this pass to LinkedIn: process only the LinkedIn source, mark Indeed as 'skipped (not in this pass)', and never open Indeed in this phase. Then, if applications.enabled is true, load job-apply and follow it for today's matched LinkedIn rows only: fill and submit external forms when applications.externalApply is true, never touch a platform one-click apply, and never apply to the same vacancy twice across platforms. Then load linkedin-feed-jobs and run its keyword search plus Recent-feed supplement, adding matching feed jobs to today's daily report. Do NOT send the summary email in this phase. Update job-index.json and append the run audit with per-source counts. Publish the daily report to common.reportRepo. $SERIAL_RULE $STOP_RULE Report the report path, LinkedIn counts, applications filled/submitted/blocked, feed-jobs added, publish status and limitations."

INDEED_PROMPT="Run today's job-search pass for Indeed only. Load job-discovery and follow it exactly, scoping this pass to Indeed: process only the Indeed source and never open LinkedIn Jobs in this phase. Use platforms.Indeed.search exactly as configured (queryMode, queries, lookbackHours, filters). Skip every vacancy already applied to on another platform (common.dedupe.skipApplied) and every job already in reports/job-index.json with appliedOn or an applyStatus in filled/submitted/blocked/failed. Then, if applications.enabled is true, load job-apply and follow it for today's matched Indeed rows only: fill and submit external forms when applications.externalApply is true, never touch Indeed Apply / Schnellbewerbung, and never apply to the same vacancy twice. If notifications.email.enabled is true, send exactly one run summary covering the whole day. Update job-index.json and append the run audit with per-source counts. Publish the daily report to common.reportRepo. $SERIAL_RULE $STOP_RULE Report the report path, Indeed counts, applications filled/submitted/blocked, jobs skipped because they were already applied to, publish status, email status and limitations."

run_phase linkedin "$LINKEDIN_PROMPT" "Job Hunter LinkedIn"
linkedin_code=$?

run_phase indeed "$INDEED_PROMPT" "Job Hunter Indeed"
indeed_code=$?

print -r -- "=== $(date) daily run finished (linkedin=$linkedin_code indeed=$indeed_code) ===" >> "$LOG"

if [[ $linkedin_code -ne 0 || $indeed_code -ne 0 ]]; then
  exit 1
fi
exit 0
