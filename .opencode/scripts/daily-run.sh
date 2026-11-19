#!/bin/zsh
# Daily Job Hunter run, intended for launchd.
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
mkdir -p "$HOME/Library/Logs" "$REPO/reports/runs"

cd "$REPO" || { print -r -- "$(date) repo unavailable: $REPO" >> "$LOG"; exit 1; }

# The browse extension needs Chrome; bring it up quietly if it is closed.
if ! pgrep -x "Google Chrome" >/dev/null 2>&1; then
  open -g -a "Google Chrome"
  sleep 8
fi

print -r -- "=== $(date) start ===" >> "$LOG"
opencode run \
  --agent job-hunter \
  --model "$MODEL" \
  --auto \
  --archived \
  --title "Job Hunter + Feed Jobs $(date +%F)" \
  "Run today's job search: load job-discovery and follow it exactly. If applications.enabled is true, load job-apply and fill only matched, non-third-party jobs whose Apply button redirects to a third-party page; never touch Easy Apply, never click Submit, and leave every filled tab open for the user. Then load linkedin-feed-jobs and run its keyword search plus Recent-feed supplement, adding matching feed jobs to today's daily report. Update job-index.json and the run audit. Publish the daily report to reportRepo. If notifications.email.enabled is true, send one job-search summary. Report the report path, counts, applications filled/blocked, feed-jobs added, publish status, email status and limitations." \
  >> "$LOG" 2>&1
exit_code=$?
print -r -- "=== $(date) exit $exit_code ===" >> "$LOG"

exit $exit_code
