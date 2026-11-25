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

# Shared single-instance lock: never drive the same browser from two runs.
LOCK="$REPO/reports/runs/.daily-run.lock"
if [ -f "$LOCK" ]; then
  holder="$(cat "$LOCK" 2>/dev/null)"
  if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
    print -r -- "=== $(date) start refused: another job-hunter run is active (pid $holder) ===" >> "$LOG"
    exit 3
  fi
  print -r -- "=== $(date) stale lock removed (pid ${holder:-unknown}) ===" >> "$LOG"
  rm -f "$LOCK"
fi
print -r -- "$$" > "$LOCK"
trap 'rm -f "$LOCK"' EXIT INT TERM HUP

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
  "Run today's LinkedIn feed pass: load linkedin-feed-review and linkedin-feed-jobs and follow them exactly. This is the only run that searches feed hiring posts; a normal job-search run never touches the feed. linkedin-feed-review searches LinkedIn posts by the configured frontend and Node.js-fullstack topics in Germany — never the user's home feed — and selects up to platforms.LinkedIn.feedReview.maxPosts (3) posts worth commenting on, with possible comment answers. linkedin-feed-jobs runs its keyword searches from platforms.LinkedIn.feedJobs first, then the configured Recent feed supplement. Apply each skill's config gates; fewer than three comments or zero selected is valid. Write the feed report and, when job rows match, add them to today's daily report. Publish written reports to common.reportRepo. If notifications.email.enabled is true, send one combined feed email. Never post, comment, react, follow, connect or message. If any platform shows a trust signal — verify you are human, CAPTCHA, unusual activity, automated access, are you a robot, an AI-agent warning, or a forced re-login/2FA — stop the entire run immediately, submit nothing further, report the exact dialog text and hand control back. Report both report paths, counts, publish status, email status and limitations." \
  >> "$LOG" 2>&1
exit_code=$?
print -r -- "=== $(date) feed review exit $exit_code ===" >> "$LOG"

exit $exit_code
