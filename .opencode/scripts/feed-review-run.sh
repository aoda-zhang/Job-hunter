#!/bin/zsh
# Daily LinkedIn feed review, intended for launchd.
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

LOG="$HOME/Library/Logs/jobhunter-feed-review.log"
MODEL="${JOB_HUNTER_MODEL:-deepseek/deepseek-flash}"
mkdir -p "$HOME/Library/Logs" "$REPO/reports/linkedin-feed"

cd "$REPO" || { print -r -- "$(date) repo unavailable: $REPO" >> "$LOG"; exit 1; }

# The browse extension needs Chrome; bring it up quietly if it is closed.
if ! pgrep -x "Google Chrome" >/dev/null 2>&1; then
  open -g -a "Google Chrome"
  sleep 8
fi

print -r -- "=== $(date) feed review start ===" >> "$LOG"
opencode run \
  --agent job-hunter \
  --model "$MODEL" \
  --auto \
  --archived \
  --title "LinkedIn Feed Review $(date +%F)" \
  "Run today's LinkedIn feed review: load linkedin-feed-review and follow it exactly. Refresh the following list from Manage Follows, read the Recent feed, hard-filter politics, jokes, personal life and other low-value posts, select only posts worth replying to, draft primary and backup replies, and write reports/linkedin-feed/$(date +%F).md. Do not run linkedin-feed-jobs; it runs with the daily job search. Do not send email. Never post, comment, react, follow, connect or message. Finally report the report path, counts, following-list refresh time and any access limitation." \
  >> "$LOG" 2>&1
exit_code=$?
print -r -- "=== $(date) feed review exit $exit_code ===" >> "$LOG"

exit $exit_code
