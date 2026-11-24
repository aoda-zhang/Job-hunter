---
name: linkedin-feed-jobs
description: Search LinkedIn posts by hiring keywords for the titles, locations and time window in job-hunter.config.json, add matches to this run's timestamped report under Feed-sourced jobs, and ignore all non-matching posts. Read-only.
---

# LinkedIn Feed Jobs

Read-only. Find hiring posts through keyword search plus a Recent-feed pass, match them against the config, add matches to that feed pass's report. This skill runs **only inside the feed pass** (`feed-review-run.sh`, next to `linkedin-feed-review`); a normal job-search run must never load it or open the LinkedIn feed. Never apply, message, like, comment, react, repost, follow or connect. Never change `job-discovery` output.

## 1. Read config

Read `job-hunter.config.json`:

- `common.countries`, `common.locations` — hard location gate. Empty `common.locations` = the whole country.
- `common.jobTitles.include` — hard role gate, also the source of search terms.
- `platforms.LinkedIn.feedJobs.lookbackHours` (falling back to `common.lookbackHours`) — hard time gate for feed posts.
- `platforms.LinkedIn.feedJobs` — optional search settings:
  - `enabled` (default `true`).
  - `searchKeywords` — the hiring keywords to search; stop and ask when missing or empty.
  - `maxQueries` (default `12`), `maxPagesPerQuery` (default `3`), `maxScreens` (default `6`).
  - `locationTerms` (default empty) — extra search terms; when empty, use `common.locations`, then `common.countries`.
  - `includeRecentFeed` (default `true`).
- `common.thirdPartyPostings` — third-party posting handling: `exclude` rejects them, `separate` and `include` keep them and note the client when stated.
- `common.technicalKeywords`, `common.workModes`, `common.employmentTypes`, `common.seniority`, `common.jdLanguages` — soft signals, recorded in Notes; they never drop a post.
- `common.preferredReportLanguage`, `common.reportRepo`.

Stop and ask when `common.jobTitles.include` or `common.countries` is empty. When `platforms.LinkedIn.feedJobs.enabled` is `false`, report that the feed job search is disabled and stop.

## 2. Search

Follow `.opencode/skills/linkedin-feed-jobs/references/search.md`.

- Build a prioritized query list from the base titles, `searchKeywords` and location terms.
- Cap at `maxQueries`; read at most `maxPagesPerQuery` pages per query.
- Set the `datePosted` bucket from the feed window (`platforms.LinkedIn.feedJobs.lookbackHours`, else `common.lookbackHours`) and verify it is active before reading.
- Do not search the following list, apply filters outside the config, or open profiles for discovery.

## 3. Recent feed supplement

When `includeRecentFeed` is `true`, run one Recent-feed pass after the searches: open `https://www.linkedin.com/feed/`, set `Sort by: Recent`, read `div[role="listitem"][componentkey*="update-card"]`, scroll `#workspace`, read at most `maxScreens` screens.

Do not apply `platforms.LinkedIn.feedReview.excludeTopics` in this skill. Hiring posts are the target.

## 4. Match

Follow `.opencode/skills/linkedin-feed-jobs/references/matching.md`.

Hard gates, stop at the first failure: hiring signal, job title, stated location, time window, third-party gate only when `common.thirdPartyPostings` is `exclude`, validity.

Soft signals, never a drop: stack, work mode, employment type, seniority, JD language. Put them in `Notes`.

If the post states no location or no specific role, skip. Never infer a location from the author's profile, the company headquarters or the post language. Never guess the company.

## 5. Deduplicate

Read every run report of today (`reports/daily/YYYY-MM-DD/YYYY-MM-DD-*.md`) and every run report of the previous 7 dates before adding a row. Never read `reports/job-index.json`.

Skip when:

- the canonical permalink, or the normalized company + title + location, already appears in an earlier run report of today;
- the job has `appliedOn` set in the index, or appears as `Submitted` / `Filled (awaiting submit)` in the last 30 days of `reports/applications/*.md`;
- the job is already `matched` or `review` in the index;
- two posts describe the same job; keep the newer or the one that states more fields;
- the job already appears in a matched or review table of an earlier run report today.

## 6. Add to this run's report

Edit the report file this run created: `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/report.md` (`HHMM` = this run's start time). Never write into another run's file and never create a day-total file.

- Place a translated `## Feed-sourced jobs` section after matched jobs and the agency/third-party section, and before review and excluded.
- If the report is missing, create it with the run header (run id, start and end time, sources, scope, apply-dedupe result) and this section; note that job-discovery has not written its sections.
- Append new rows to this run's file; never duplicate a row, rewrite a matched/review row or overwrite a user-edited row.
- If a run summary table exists, set its `Feed-sourced jobs` row to the row count. Do not create a run summary table.
- List only matches. Never list non-matching hiring posts or non-hiring posts anywhere, including the excluded table.
- If nothing matches, do not add the section.

Use these columns:

```markdown
| # | Source | Company | Title | Location | Mode | Posted | Matched keywords | Notes | Link |
|---|---|---|---|---|---|---|---|---|---|
| 1 | LinkedIn Search | Example GmbH | <configured title> | <configured location> | Hybrid | 2h ago | <configured keyword> | From search; hiring manager post | [Open](URL) |
```

- `Source`: `LinkedIn Search` for a keyword-search hit, `LinkedIn Feed` for a Recent-feed hit.
- `Company`: the employer named in the post. Never guess.
- `Title`: the role as written.
- `Location`: the location as written. Never infer.
- `Mode`: the stated mode, or `Not specified`.
- `Posted`: the relative time (`2h ago`, `1 day ago`); add `24h boundary` in Notes when applicable.
- `Matched keywords`: configured terms named in the post; `None matched` when a stack is named but no term matches; `Not stated` when no stack is named.
- `Notes`: start with `From search` or `From feed` (translated in the report language), then one verifiable fact. Append soft-note phrases with `;`.
- `Link`: the permalink found in the post or copied from its menu; `Link unavailable` when none exists. Never assemble a URL.

Renumber `#` after merging.

## 7. Publish

Only when this skill is the only writer of the run report: if `common.reportRepo` is set, run `.opencode/scripts/report-publish.sh <local report> reports/<YYYY-MM-DD>/YYYY-MM-DD-HHMM/report.md "docs: add feed-sourced jobs for YYYY-MM-DD HH:MM"`; it pushes and arms the one-shot expiry timer. Never merge into another run's remote file. On failure, report it and keep the local file. Never force-push. Published copies expire per `common.reportExpiryHours`; with `reportExpiryMode: "delete-repo"` the repo itself is deleted, so recreate it with `gh repo create <owner>/<name> --public` when the clone reports it missing. A remote that the cleanup removed is expected, not a failed push.

When `job-discovery` runs in the same pass, the orchestrator publishes after this step: do not push. Never send email; the orchestrator sends one run summary.

## 8. Finish

Report queries run, pages read, cards seen, hiring posts seen, rows added, skipped for missing title or location, skipped as duplicate or applied, this run's report path, publish status and limitations. Count only posts actually rendered. A zero result is valid.
