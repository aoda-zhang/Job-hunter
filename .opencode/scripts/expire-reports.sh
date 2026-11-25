#!/bin/zsh
# Expire reports pushed to common.reportRepo.
#
# Published units (reports/<date>/<date>-HHMM/ or reports/linkedin-feed/<date>.md)
# are kept while they are younger than common.reportExpiryHours. Once a unit
# expires, common.reportExpiryMode decides what happens to the GitHub copy:
#
#   purge-history  rebuild the branch as one new root commit holding only the
#                  fresh units plus .expiry.json, then force-push with lease.
#                  Expired commit history is no longer reachable from the branch.
#   delete-repo    delete the GitHub repository entirely, so no content and no
#                  commit record is left. The next publish recreates it.
#
# Local reports are never touched.
#
# Usage: expire-reports.sh [--dry-run] [--purge-now]
#   --dry-run    show what would happen, change nothing
#   --purge-now  act now, keeping every unit currently in HEAD
set -u
setopt NULL_GLOB

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="${JOB_HUNTER_CONFIG:-$REPO/job-hunter.config.json}"
CACHE="${JOB_HUNTER_REPORT_CACHE:-$HOME/Library/Caches/job-hunter/report-repo}"
LOCK="$CACHE.lock"
LOG="${JOB_HUNTER_EXPIRE_LOG:-$HOME/Library/Logs/jobhunter-expire.log}"
MANIFEST=".expiry.json"

# launchd starts us with a minimal PATH.
export PATH="$HOME/Library/pnpm/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

DRY_RUN=0
PURGE_NOW=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --purge-now) PURGE_NOW=1 ;;
    *) print -u2 -- "unknown argument: $arg"; exit 2 ;;
  esac
done

log() { print -r -- "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

if [ ! -r "$CONFIG" ]; then
  log "config not found: $CONFIG"
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  log "jq is required"
  exit 2
fi

REMOTE="$(jq -r '.common.reportRepo // empty' "$CONFIG")"
HOURS="$(jq -r '.common.reportExpiryHours // empty' "$CONFIG")"
MODE="$(jq -r '.common.reportExpiryMode // "purge-history"' "$CONFIG")"

case "$MODE" in
  purge-history|delete-repo) ;;
  *) log "invalid common.reportExpiryMode: $MODE (use purge-history or delete-repo)"; exit 2 ;;
esac

# owner/name from https://github.com/owner/name(.git)
SLUG="$(print -r -- "$REMOTE" | sed -E 's#^.*github\.com[:/]##' | sed -E 's#\.git$##; s#/$##')"

[ -n "$REMOTE" ] || exit 0
if [ -z "$HOURS" ] || [ "$HOURS" = "null" ] || [ "$HOURS" = "0" ]; then
  [ "$PURGE_NOW" = "1" ] || exit 0
  HOURS=0
fi
if ! [[ "$HOURS" =~ '^[0-9]+([.][0-9]+)?$' ]]; then
  log "invalid common.reportExpiryHours: $HOURS"
  exit 2
fi
TTL="$(awk -v h="$HOURS" 'BEGIN { printf "%d", h * 3600 }')"

mkdir -p "$HOME/Library/Logs" "$(dirname "$CACHE")"

# One cleanup at a time: a slow push must not race the next timer tick.
if ! mkdir "$LOCK" 2>/dev/null; then
  holder="$(cat "$LOCK/pid" 2>/dev/null)"
  if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
    exit 0
  fi
  rm -rf "$LOCK"
  mkdir "$LOCK" 2>/dev/null || exit 0
fi
print -r -- $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT INT TERM HUP

if [ "$MODE" = "delete-repo" ]; then
  if ! command -v gh >/dev/null 2>&1; then
    log "gh is required for delete-repo mode"
    exit 2
  fi
  if ! gh repo view "$SLUG" >/dev/null 2>&1; then
    # Already deleted (or never created): nothing to clean.
    exit 0
  fi
fi

if [ ! -d "$CACHE/.git" ]; then
  rm -rf "$CACHE"
  if ! git clone --quiet "$REMOTE" "$CACHE"; then
    log "clone failed: $REMOTE"
    exit 1
  fi
fi

cd "$CACHE" || { log "cache unavailable: $CACHE"; exit 1; }
git remote set-url origin "$REMOTE"

typeset -ga UNITS FRESH EXPIRED
typeset -A KEEP

enumerate_units() {
  UNITS=()
  for d in reports/*(N/); do
    [ "${d%/}" = "reports/linkedin-feed" ] && continue
    for run in "${d%/}"/*(N/); do
      UNITS+=("${run%/}")
    done
    if [ -n "$(find "$d" -maxdepth 1 -type f -print -quit 2>/dev/null)" ]; then
      UNITS+=("${d%/}")
    fi
  done
  for f in reports/linkedin-feed/*(N.); do
    UNITS+=("$f")
  done
}

# Reads .expiry.json (unit -> original publish epoch), falls back to the commit
# that last touched the unit for entries the manifest does not know yet.
load_state() {
  local now unit ts
  now="$(date +%s)"
  KEEP=()
  FRESH=()
  EXPIRED=()

  typeset -A SEEN
  if [ -f "$MANIFEST" ]; then
    while IFS=$'\t' read -r unit ts; do
      [ -n "$unit" ] && SEEN[$unit]="$ts"
    done < <(jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$MANIFEST" 2>/dev/null)
  fi

  enumerate_units
  for unit in "${UNITS[@]}"; do
    if [ -n "${SEEN[$unit]:-}" ]; then
      ts="${SEEN[$unit]}"
    else
      ts="$(git log -1 --format=%ct -- "$unit" 2>/dev/null)"
      [ -n "$ts" ] || ts="$now"
    fi
    if [ "$PURGE_NOW" = "1" ] || [ $(( now - ts )) -lt "$TTL" ]; then
      FRESH+=("$unit")
      KEEP[$unit]="$ts"
    else
      EXPIRED+=("$unit")
    fi
  done
}

write_manifest() {
  local out="$1" unit
  shift
  {
    for unit in "$@"; do
      print -r -- "$unit"$'\t'"${KEEP[$unit]:-0}"
    done
  } | jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | { (.[0]): (.[1] | tonumber) }) | add // {}' > "$out"
}

rebuild_history() {
  local stage attempt remote_sha
  stage="$(mktemp -d "${TMPDIR:-/tmp}/report-purge.XXXXXX")" || return 1

  # Keep every non-report file (README, license, dotfiles, ...) and every fresh unit.
  local unit
  find . -mindepth 1 -maxdepth 1 ! -name .git ! -name reports ! -name "$MANIFEST" \
    -exec cp -R {} "$stage/" \; 2>/dev/null
  for unit in "${FRESH[@]}"; do
    mkdir -p "$stage/${unit:h}"
    cp -R "$unit" "$stage/$unit"
  done
  if [ ${#FRESH[@]} -gt 0 ]; then
    write_manifest "$stage/$MANIFEST" "${FRESH[@]}"
  else
    rm -f "$stage/$MANIFEST"
  fi

  git branch -D "purge-$$" >/dev/null 2>&1 || true
  if ! git checkout --quiet --orphan "purge-$$"; then
    log "cannot create orphan branch"
    rm -rf "$stage"
    return 1
  fi
  git rm -rf --cached -q . >/dev/null 2>&1 || true
  find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  cp -R "$stage/." .
  rm -rf "$stage"

  local git_name git_email
  git_name="${JOB_HUNTER_GIT_NAME:-$(git config --get user.name)}"
  git_email="${JOB_HUNTER_GIT_EMAIL:-$(git config --get user.email)}"
  [ -n "$git_name" ] || git_name="job-hunter"
  [ -n "$git_email" ] || git_email="job-hunter@localhost"

  git add -A
  if ! git -c user.name="$git_name" -c user.email="$git_email" \
    commit --allow-empty -q -m "test something"; then
    log "commit failed"
    return 1
  fi

  remote_sha="$(git rev-parse "origin/$BRANCH")"
  if git push --quiet --force-with-lease="refs/heads/$BRANCH:$remote_sha" origin "HEAD:$BRANCH"; then
    return 0
  fi
  return 1
}

git fetch --quiet --prune origin || { log "fetch failed: $REMOTE"; exit 1; }
BRANCH="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
[ -n "$BRANCH" ] || BRANCH=main

if [ "$DRY_RUN" = "1" ]; then
  git checkout --quiet -B "$BRANCH" "origin/$BRANCH" || exit 1
  git reset --hard --quiet "origin/$BRANCH" || exit 1
  git clean -fdq
  load_state
  if [ "$MODE" = "delete-repo" ]; then
    if [ "$PURGE_NOW" != "1" ] && [ ${#EXPIRED[@]} -eq 0 ]; then
      print -r -- "no published unit older than ${HOURS}h"
      exit 0
    fi
    print -r -- "would delete the report repo $SLUG (no content, no commit left behind)"
    exit 0
  fi
  if [ "$PURGE_NOW" = "1" ]; then
    print -r -- "would rewrite history now, keeping ${#FRESH[@]} unit(s) and dropping all commits"
    exit 0
  fi
  if [ ${#EXPIRED[@]} -eq 0 ]; then
    print -r -- "no published unit older than ${HOURS}h"
    exit 0
  fi
  print -r -- "would expire ${#EXPIRED[@]} unit(s) older than ${HOURS}h and rewrite history, keeping ${#FRESH[@]}:"
  print -l -- "${EXPIRED[@]}"
  exit 0
fi

attempt=0
while true; do
  attempt=$((attempt + 1))
  if [ "$attempt" -gt 3 ]; then
    log "gave up after 3 attempts"
    exit 1
  fi

  if ! git fetch --quiet --prune origin; then
    log "fetch failed: $REMOTE"
    exit 1
  fi
  if ! git checkout --quiet -B "$BRANCH" "origin/$BRANCH"; then
    log "checkout failed: $BRANCH"
    exit 1
  fi
  git reset --hard --quiet "origin/$BRANCH" || { log "reset failed"; exit 1; }
  git clean -fdq

  load_state
  if [ ${#EXPIRED[@]} -eq 0 ] && [ "$PURGE_NOW" != "1" ]; then
    print -r -- "no published unit older than ${HOURS}h"
    exit 0
  fi

  if [ "$MODE" = "delete-repo" ]; then
    if gh repo delete "$SLUG" --yes >/dev/null 2>&1; then
      log "deleted report repo $SLUG: content and history gone"
      print -r -- "deleted report repo $SLUG"
      exit 0
    fi
    log "gh repo delete failed for $SLUG (is the delete_repo scope granted?)"
    exit 1
  fi

  if rebuild_history; then
    if [ ${#EXPIRED[@]} -gt 0 ]; then
      log "expired ${#EXPIRED[@]} unit(s) older than ${HOURS}h, rewrote history, kept ${#FRESH[@]}: ${(j:, :)EXPIRED}"
      print -r -- "expired ${#EXPIRED[@]} unit(s), kept ${#FRESH[@]}, history rewritten"
    else
      log "rewrote history, kept ${#FRESH[@]} unit(s)"
      print -r -- "history rewritten, kept ${#FRESH[@]} unit(s)"
    fi
    exit 0
  fi
  log "force-push rejected (attempt $attempt); refetching and rebuilding"
done
