#!/bin/zsh
# Daily Job Hunter run, intended for launchd.
# Runs each source in its own OpenCode session, in `sources` order, to keep
# every session small: LinkedIn (discovery + apply), then Indeed.
# Feed hiring-post search belongs only to the separate feed pass
# (feed-review-run.sh); a job-search run must never touch the feed.
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

# One report file per run, named to the minute. Each phase is its own run.
RUN_STAMP="$(date +%Y-%m-%d-%H%M)"
RUN_DAY="${RUN_STAMP:0:10}"
RUN_HUMAN="$(date '+%Y-%m-%d %H:%M')"
export JOB_HUNTER_RUN_STAMP="$RUN_STAMP"
export JOB_HUNTER_RUN_DAY="$RUN_DAY"
print -r -- "=== $(date) run stamp $RUN_STAMP ===" >> "$LOG"

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

LINKEDIN_PROMPT="Run today's job-search pass for LinkedIn only. Load job-discovery and follow it exactly, scoping this pass to LinkedIn: process only the LinkedIn source, mark Indeed as 'skipped (not in this pass)', and never open Indeed in this phase. Submit one query per common.searchTitles entry, one at a time, and run the three steps in order: step 1 collect cards only and write the job-audit table, step 2 merge and apply the shallow title filter, step 3 open one JD at a time and classify it. Your report file for this run is reports/daily/${JOB_HUNTER_RUN_DAY}/${JOB_HUNTER_RUN_STAMP}/report.md with start time ${RUN_HUMAN}: create it fresh, never merge another run's file, and put the run header (run id, start, end, sources, scope, apply-dedupe result) at the top. Every job listed in the most recent earlier run report is a hard skip (the 24-hour window makes older runs irrelevant): do not open it, do not list it, do not apply to it again; if the whole result set is already covered, report 0 new and stop. Before the first platform, rebuild the applied set from reports/job-index.json and the last 30 days of reports/applications/*.md and write the result into the header. Then, if applications.enabled is true, load job-apply and follow it for this run's matched LinkedIn rows only: fill and submit external forms when applications.externalApply is true, never touch a platform one-click apply, and never apply to the same vacancy twice across platforms. When germanJdPass.enabled is true, run Part 2 only after this report is written, published and (if enabled) emailed: load job-apply section 1a and job-discovery/references/german-jd-pass.md, work reports/runs/both-lan-queue.md then this run's german-jd-audit.md, work the whole list one posting at a time with no cap (apply to the strong matches, record the filter reason for the rest), write both-lan.md and republish the run folder. Part 2 must never edit report.md, job-audit.md or german-jd-audit.md or change Part 1 counts. Do not load linkedin-feed-jobs and do not open the LinkedIn feed in this pass: feed hiring posts are searched only by the separate feed pass (feed-review-run.sh). Every matched job gets a cover letter, Easy Apply included. Update job-index.json and append the run audit at the end with the real finishedAt, durationSeconds and reportPath. Publish this run's report to common.reportRepo in that repo's day folder reports/${JOB_HUNTER_RUN_DAY}/${JOB_HUNTER_RUN_STAMP}/report.md. When report, index, audit and publish are done, if notifications.email.enabled is true send exactly one summary email for this run (subject '[Job Hunter] ${RUN_HUMAN} · <matched> matched'). $SERIAL_RULE $STOP_RULE Report the report path, LinkedIn counts, applications filled/submitted/blocked, cover letters written, publish status, email status and limitations."

INDEED_PROMPT="Run today's job-search pass for Indeed only. Load job-discovery and follow it exactly, scoping this pass to Indeed: process only the Indeed source and never open LinkedIn Jobs or the LinkedIn feed in this phase. Use platforms.Indeed.search exactly as configured (queryMode, searchTitles, lookbackHours, filters), run the three steps in order, and write the job-audit table. Your report file for this run is reports/daily/${JOB_HUNTER_RUN_DAY}/${JOB_HUNTER_RUN_STAMP}/report.md with start time ${RUN_HUMAN}: create it fresh, never merge another run's file, and put the run header at the top. Every job listed in the most recent earlier run report is a hard skip (the 24-hour window makes older runs irrelevant): do not open it, do not list it, do not apply to it again; if the whole result set is already covered, report 0 new and stop. Before the first platform, load the previous run report and write the duplicate-check result into the header; skip every vacancy listed there and never submit it again. Then, if applications.enabled is true, load job-apply and follow it for this run's matched Indeed rows only: fill and submit external forms when applications.externalApply is true, never touch Indeed Apply / Schnellbewerbung, and never apply to the same vacancy twice. When germanJdPass.enabled is true, run Part 2 only after this report is written, published and (if enabled) emailed: load job-apply section 1a and job-discovery/references/german-jd-pass.md, work reports/runs/both-lan-queue.md then this run's german-jd-audit.md, work the whole list one posting at a time with no cap (apply to the strong matches, record the filter reason for the rest), write both-lan.md and republish the run folder. Part 2 must never edit report.md, job-audit.md or german-jd-audit.md or change Part 1 counts. Every matched job gets a cover letter, Easy Apply included. Update job-index.json and append the run audit at the end with the real finishedAt, durationSeconds and reportPath. Publish this run's report to common.reportRepo in that repo's day folder reports/${JOB_HUNTER_RUN_DAY}/${JOB_HUNTER_RUN_STAMP}/report.md. When everything is done, if notifications.email.enabled is true send exactly one summary email for this run (subject '[Job Hunter] ${RUN_HUMAN} · <matched> matched'). $SERIAL_RULE $STOP_RULE Report the report path, Indeed counts, applications filled/submitted/blocked, jobs skipped because they were already applied to, cover letters written, publish status, email status and limitations."

run_phase linkedin "$LINKEDIN_PROMPT" "Job Hunter LinkedIn"
linkedin_code=$?

run_phase indeed "$INDEED_PROMPT" "Job Hunter Indeed"
indeed_code=$?

print -r -- "=== $(date) daily run finished (linkedin=$linkedin_code indeed=$indeed_code) ===" >> "$LOG"

if [[ $linkedin_code -ne 0 || $indeed_code -ne 0 ]]; then
  exit 1
fi
exit 0
