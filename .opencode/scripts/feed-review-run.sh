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
  --title "LinkedIn Feed Pass $(date +%F)" \
  "Run today's LinkedIn feed pass: load linkedin-feed-review and linkedin-feed-jobs and follow them exactly. linkedin-feed-jobs runs its keyword searches from job-hunter.config.json first, then the configured Recent feed supplement. linkedin-feed-review reads the Recent feed once, newest first, without the following list. Apply each skill's config gates; zero selected is valid. Write the feed report and, when job rows match, add them to today's daily report. Publish written reports to reportRepo. If notifications.email.enabled is true, send one combined feed email. Never post, comment, react, follow, connect or message. Report both report paths, counts, publish status, email status and limitations." \
  >> "$LOG" 2>&1
exit_code=$?
print -r -- "=== $(date) feed review exit $exit_code ===" >> "$LOG"

exit $exit_code
