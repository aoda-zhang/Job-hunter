#!/bin/zsh
# Verify that the application-policy prose matches job-hunter.config.json.
#
# Usage: check-apply-policy.sh
#
# The config switches are the single source of truth:
#   applications.enabled
#   applications.externalApply
#   applications.easyApply.enabled
#   germanJdPass.enabled
#
# The script fails (exit 1) when a document under .opencode/agents or
# .opencode/skills still states the opposite — for example "one-click apply is
# always left to the user" while applications.easyApply.enabled is true.
# Run it before the first application form of a run (Part 1 or Part 2).
set -u
setopt NULL_GLOB

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="$REPO/job-hunter.config.json"

if [ ! -f "$CONFIG" ]; then
  print -u2 -- "apply-policy: config not found: $CONFIG"
  exit 2
fi

CONFIG_VALUES="$(python3 - "$CONFIG" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    config = json.load(fh)

applications = config.get("applications") or {}
easy_apply = applications.get("easyApply") or {}
german_pass = config.get("germanJdPass") or {}

for key, value in (
    ("APP_ENABLED", applications.get("enabled")),
    ("EXTERNAL_APPLY", applications.get("externalApply")),
    ("EASY_APPLY", easy_apply.get("enabled")),
    ("GERMAN_PASS", german_pass.get("enabled")),
):
    print(f"{key}={'true' if value is True else 'false'}")
PY
)" || exit 2

eval "$CONFIG_VALUES"

print -- "apply-policy check"
print -- "  applications.enabled=$APP_ENABLED externalApply=$EXTERNAL_APPLY easyApply.enabled=$EASY_APPLY germanJdPass.enabled=$GERMAN_PASS"

DOCS=(
  "$REPO"/.opencode/agents/*.md
  "$REPO"/.opencode/skills/*/SKILL.md
  "$REPO"/.opencode/skills/*/references/*.md
)

# Only the "automation is on but the docs still forbid it" direction is a
# contradiction: those sentences are absolute and would override the switch.
# Conditional text ("when enabled ...") is correct and is not matched.
STALE_PATTERN='always left to the user|never fill or submit a one-click|never use a platform one-click apply|never touch a one-click apply|Easy Apply stays with the user|Easy Apply belongs to the user|One-click apply rows stay untouched|One-click apply rows stay for the user|never fill it, never submit it'

CONTRADICTIONS=()
if [ "$EASY_APPLY" = "true" ]; then
  for file in "${DOCS[@]}"; do
    [ -f "$file" ] || continue
    while IFS= read -r match; do
      CONTRADICTIONS+=("${file#"$REPO"/}:$match")
    done < <(grep -nE "$STALE_PATTERN" "$file" || true)
  done
fi

if [ ${#CONTRADICTIONS[@]} -gt 0 ]; then
  print -u2 -- "apply-policy: applications.easyApply.enabled is true, but these lines still say one-click apply is never submitted:"
  for item in "${CONTRADICTIONS[@]}"; do
    print -u2 -- "  $item"
  done
  print -u2 -- "apply-policy: FAIL — fix the prose (or the switch) before applying"
  exit 1
fi

print -- "apply-policy: OK"
exit 0
