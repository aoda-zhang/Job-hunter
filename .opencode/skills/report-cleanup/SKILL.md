---
name: report-cleanup
description: Expire reports published to common.reportRepo. After common.reportExpiryHours, rewrite the repo history or delete the repo so nothing is left on GitHub. Local reports are never touched.
---

# Report cleanup

Removes the published copy of the daily reports from `common.reportRepo`. Only
GitHub is touched: everything under the local `reports/` directory is preserved
exactly as it is.

## When to use

- The user asks to clean up, expire or remove published reports.
- The user asks to rewrite the report repo history or delete the repo.
- A publish step reports that the report repo is missing. That is expected after
  a cleanup with `delete-repo`; do not treat it as a failed publish.

## Config keys

| Key | Meaning |
|---|---|
| `common.reportRepo` | Target Git URL. Unset = nothing to clean. |
| `common.reportExpiryHours` | TTL in hours. `0` or absent disables cleanup. |
| `common.reportExpiryCheckMinutes` | Timer interval (default `15`). |
| `common.reportExpiryMode` | `purge-history` (default) or `delete-repo`. |

Modes:

- **`purge-history`** — keeps units younger than the TTL. When one expires, the
  branch is rebuilt as a single new root commit with the fresh units plus
  `.expiry.json`, then force-pushed with lease. Expired commits become
  unreachable from the branch, but a new "purge" commit remains.
- **`delete-repo`** — deletes the GitHub repository entirely once a unit is
  older than the TTL. No content and no commit record is left. The next publish
  must recreate the repo.

`.expiry.json` in the report repo records each unit's original publish time so a
rewritten history cannot extend its lifetime. It only exists while at least one
unit is still fresh; once everything expired the repo is left with no files at
all. Never edit it by hand.

## Running it

The launchd task `ai.jobhunter.expire` runs the script every
`common.reportExpiryCheckMinutes`. Do not duplicate its work unless the user
asks for a manual run.

```sh
# what would happen, no changes
.opencode/scripts/expire-reports.sh --dry-run

# apply the TTL now
.opencode/scripts/expire-reports.sh

# act immediately: purge history now, or delete the repo now
.opencode/scripts/expire-reports.sh --purge-now
```

`--purge-now` is irreversible on GitHub (force-push or repo deletion). Confirm
with the user before running it by hand.

## Invariants

- Never delete, rewrite or move anything under the local `reports/` directory.
- Never force-push without `--force-with-lease`.
- `delete-repo` needs `gh` authenticated with the `delete_repo` scope
  (`gh auth refresh -h github.com -s delete_repo`).
- After `delete-repo`, publish recreates the repo with
  `gh repo create <owner>/<name> --public` before pushing.
- A report or repo that is missing because it expired is expected. Never
  re-push expired content and never report it as a publish failure.
- Report exactly which units were removed, which were kept, and the remote state.
