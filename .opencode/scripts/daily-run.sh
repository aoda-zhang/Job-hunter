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
  "Run today's job search: follow the job-discovery flow exactly as job-hunter.config.json specifies; when finished update reports/job-index.json and reports/runs/$(date +%F).jsonl. Then load linkedin-feed-jobs and run its standalone feed pass; do not run linkedin-feed-review because it has its own timer. Add only matching feed hiring posts to reports/daily/$(date +%F).md under the Feed-sourced jobs section, ignore non-matching posts, and do not put them in the excluded table. After adding rows, publish the updated daily report to reportRepo and verify that the remote file contains the Feed-sourced jobs section when rows were added; if not, publish again. If notifications.email.enabled is true, load the email-notify skill and send the job-search run summary. Finally report the report path, matched count, review count, applied-skipped count, possible-duplicate count, feed-jobs added count, publish status, and per-source result counts, pages opened and stop reason." \
  >> "$LOG" 2>&1
exit_code=$?
print -r -- "=== $(date) exit $exit_code ===" >> "$LOG"

exit $exit_code
