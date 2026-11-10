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
  --title "Job Hunter $(date +%F)" \
  "运行今天的职位搜索：严格按 job-hunter.config.json 执行 job-discovery 流程；完成后更新 reports/job-index.json 和 reports/runs/$(date +%F).jsonl；如果 notifications.email.enabled 为 true，加载 email-notify 技能并发送运行摘要；最后报告日报路径、命中数、复核数、已投递跳过数、疑似重复数，以及 LinkedIn 结果数、翻页数和停止原因。" \
  >> "$LOG" 2>&1
exit_code=$?
print -r -- "=== $(date) exit $exit_code ===" >> "$LOG"

exit $exit_code
