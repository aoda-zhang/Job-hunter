#!/bin/zsh
# Publish one report unit to common.reportRepo and schedule its expiry.
#
# Replaces the manual "clone / copy / commit / push" step in the skills and adds
# the one-shot cleanup timer, so a report lives on GitHub for exactly
# reportExpiryHours and then disappears. Never force-pushes.
#
# Usage: report-publish.sh <local-path> <path-in-repo> [ignored]
#   report-publish.sh reports/daily/2026-11-24/2026-11-24-1500 \
#       reports/2026-11-24/2026-11-24-1500
#
# A run folder is published as a filtered tree: only report artifacts
# (report.md, job-audit.md, german-jd-audit.md, both-lan.md, per-vacancy
# fields.json / cover-letter.json / *.pdf) are copied. Hidden scratch files
# (.step2.py, .q1.tsv, .DS_Store, ...) never reach the report repo. A legacy
# destination ending in report.md publishes the folder that contains it, so old
# invocations keep working without creating a directory named report.md.
#
# A file source is published as that single file (e.g. a feed review markdown).
#
# Every publish is committed with the fixed message "test something"; a
# third argument is accepted for backwards compatibility but ignored.
set -u
setopt NULL_GLOB

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="${JOB_HUNTER_CONFIG:-$REPO/job-hunter.config.json}"
CACHE="${JOB_HUNTER_REPORT_CACHE:-$HOME/Library/Caches/job-hunter/report-repo}"
LOCK="$CACHE.lock"
LOG="${JOB_HUNTER_PUBLISH_LOG:-$HOME/Library/Logs/jobhunter-publish.log}"

SRC="${1:-}"
DEST="${2:-}"
MSG="test something"

log() { print -r -- "$(date '+%Y-%m-%d %H:%M:%S') [publish] $*" >> "$LOG"; }

if [ -z "$SRC" ] || [ -z "$DEST" ]; then
  print -u2 -- "usage: report-publish.sh <local-path> <path-in-repo> [ignored]"
  exit 2
fi
[ -e "$SRC" ] || { print -u2 -- "source not found: $SRC"; exit 2; }
SRC_ABS="$(cd "$(dirname "$SRC")" && pwd)/${SRC:t}"

# Keep every write inside the report cache.
case "/$DEST/" in
  //*|*/../*|*/..) print -u2 -- "invalid destination: $DEST"; exit 2 ;;
esac

if ! command -v jq >/dev/null 2>&1; then
  print -u2 -- "jq is required"
  exit 2
fi
REMOTE="$(jq -r '.common.reportRepo // empty' "$CONFIG")"
MODE="$(jq -r '.common.reportExpiryMode // "purge-history"' "$CONFIG")"
[ -n "$REMOTE" ] || { print -r -- "no common.reportRepo; nothing to publish"; exit 0; }

SLUG="$(print -r -- "$REMOTE" | sed -E 's#^.*github\.com[:/]##' | sed -E 's#\.git$##; s#/$##')"

mkdir -p "$(dirname "$CACHE")" "$(dirname "$LOG")"

# One writer at a time (same lock the cleanup uses).
if ! mkdir "$LOCK" 2>/dev/null; then
  holder="$(cat "$LOCK/pid" 2>/dev/null)"
  if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
    print -u2 -- "another publish/cleanup is running (pid $holder)"
    exit 1
  fi
  rm -rf "$LOCK"
  mkdir "$LOCK" 2>/dev/null || exit 1
fi
print -r -- $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT INT TERM HUP

if [ ! -d "$CACHE/.git" ]; then
  rm -rf "$CACHE"
  if ! git clone --quiet "$REMOTE" "$CACHE" 2>/dev/null; then
    if [ "$MODE" = "delete-repo" ] && command -v gh >/dev/null 2>&1; then
      log "clone failed, recreating $SLUG"
      gh repo create "$SLUG" --public >/dev/null 2>&1 || true
    fi
    if ! git clone --quiet "$REMOTE" "$CACHE"; then
      log "clone failed: $REMOTE"
      print -u2 -- "clone failed: $REMOTE"
      exit 1
    fi
  fi
fi

cd "$CACHE" || exit 1
git remote set-url origin "$REMOTE"
git fetch --quiet --prune origin || { print -u2 -- "fetch failed: $REMOTE"; exit 1; }
BRANCH="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
[ -n "$BRANCH" ] || BRANCH=main
if git rev-parse --verify --quiet "origin/$BRANCH" >/dev/null 2>&1; then
  git checkout --quiet -B "$BRANCH" "origin/$BRANCH" || exit 1
  git reset --hard --quiet "origin/$BRANCH" || exit 1
  git clean -fdq
else
  # Fresh/empty remote: start an orphan branch.
  git checkout --quiet --orphan "$BRANCH" 2>/dev/null || git checkout --quiet -B "$BRANCH"
  git rm -rf --cached -q . >/dev/null 2>&1 || true
  find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} + 2>/dev/null || true
fi

# Drop anything under reports/ that is not a report artifact. This also heals
# helper files pushed by older versions of this script.
prune_report_repo() {
  local f rel
  [ -d reports ] || return 0
  # Heal the old bug where a run folder was copied into a directory named
  # report.md: a report file name is never a directory.
  find reports -type d -name '*.md' -prune -exec rm -rf {} + 2>/dev/null || true
  while IFS= read -r f; do
    rel="${f#reports/}"
    case "$rel" in
      *.md|*.pdf|*/fields.json|fields.json|*/cover-letter.json|cover-letter.json) ;;
      *) rm -f "$f" ;;
    esac
  done < <(find reports -type f 2>/dev/null)
  find reports -type d -empty -delete 2>/dev/null || true
}
prune_report_repo

# Report artifacts only. A run folder may hold hidden scratch helpers from the
# discovery steps; those are local working files, never part of the report.
copy_report_tree() {
  local src="$1" target="$2" f rel copied=0 skipped=0
  while IFS= read -r f; do
    rel="${f#$src/}"
    case "$rel" in
      *.md|*.pdf|*/fields.json|fields.json|*/cover-letter.json|cover-letter.json) ;;
      *) skipped=$((skipped + 1)); continue ;;
    esac
    mkdir -p "$target/${rel:h}"
    if ! cp "$f" "$target/$rel"; then
      return 1
    fi
    copied=$((copied + 1))
  done < <(find "$src" -type f 2>/dev/null)
  print -r -- "publish: copied $copied report file(s), skipped $skipped non-report file(s)" >&2
  return 0
}

if [ -d "$SRC_ABS" ]; then
  # Run folder. A legacy destination naming the report file points at the
  # folder that contains it; otherwise the destination is the folder itself.
  if [ "${DEST:t}" = "report.md" ]; then
    DEST="${DEST:h}"
  fi
  case "$DEST" in
    ""|.|/) print -u2 -- "invalid destination for a run folder"; exit 2 ;;
  esac
  target="$CACHE/$DEST"
  mkdir -p "$(dirname "$target")"
  rm -rf "$target"
  mkdir -p "$target"
  copy_report_tree "$SRC_ABS" "$target" || { print -u2 -- "copy failed: $SRC_ABS -> $target"; exit 1; }
else
  target="$CACHE/$DEST"
  mkdir -p "$(dirname "$target")"
  rm -rf "$target"
  cp "$SRC_ABS" "$target" || { print -u2 -- "copy failed: $SRC_ABS -> $target"; exit 1; }
fi

git add -A
if git diff --cached --quiet; then
  print -r -- "nothing to publish (already up to date): $DEST"
else
  git_name="${JOB_HUNTER_GIT_NAME:-$(git config --get user.name)}"
  git_email="${JOB_HUNTER_GIT_EMAIL:-$(git config --get user.email)}"
  [ -n "$git_name" ] || git_name="job-hunter"
  [ -n "$git_email" ] || git_email="job-hunter@localhost"
  git -c user.name="$git_name" -c user.email="$git_email" commit --quiet -m "$MSG" || {
    print -u2 -- "commit failed"
    log "commit failed for $DEST"
    exit 1
  }
  if ! git push --quiet origin "HEAD:$BRANCH"; then
    print -u2 -- "push failed: $REMOTE"
    log "push failed for $DEST"
    exit 1
  fi
  print -r -- "published $DEST to $SLUG"
  log "published $DEST"
fi

# Arm the one-shot cleanup for this publish.
"$REPO/.opencode/scripts/schedule-expiry.sh" || {
  print -u2 -- "warning: published, but could not schedule the expiry timer"
  log "schedule-expiry failed after publishing $DEST"
}
