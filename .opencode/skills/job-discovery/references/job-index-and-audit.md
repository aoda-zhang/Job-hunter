# Run log and application log

Local memory layer. Two files only:

| File | Purpose |
|---|---|
| `reports/runs/YYYY-MM-DD.jsonl` | Run audit, one line per run |
| `reports/applications/YYYY-MM-DD.md` | Application log for that date; the only application record |

`reports/job-index.json` is **legacy**: never read it, never write it, never use it for dedupe or application state. It may remain on disk as history only.

Both active files are Git-ignored and local only: never publish them to `common.reportRepo`.

## 1. Dedup

The skip sources are exactly two:

1. **Previous-run set** — every job ID / canonical URL in the merged list of the single most recent earlier run's `<run>/job-audit.md`, **whatever its status** (`sent to JD review`, `matched`, `needs review`, `excluded`, `deferred (German JD)`, `removed by shallow filter`, `previously reported`, `already applied (skipped)`). A vacancy the previous run merged, opened, excluded, left in review or shallow-filtered is examined once and never re-opened by the next run. Fallback only when that `job-audit.md` is missing or has no merged list: use the previous `report.md` tables and record the fallback in `limitations`. A card in this set is not opened, not judged and not listed; count it as `previously reported`.
2. **Today's applications** — every row in `reports/applications/YYYY-MM-DD.md`, mapped to normalized `company + title + city`. Those vacancies are `already applied (skipped)` on any platform.

Everything else is checked. No older run's audit is read (`common.dedupe.previousRunOnly`) and no older application log is read (`common.dedupe.checkAppliedHistory: false`).

- Override only on explicit user request (named jobs, a company, a status); exempt those keys for that run and record the exemption in `limitations`.
- The first run of a day with no earlier report and no application log checks everything.
- Add a row to today's log the moment an application is submitted, so a later pass the same day sees it.

Soft dedup: compare `normalized company + normalized title + city`, without the platform name.

- Normalize: lowercase; strip punctuation, extra spaces, `(m/w/d)`, `(f/m/d)`, `(all genders)`, and GmbH, AG, SE, Inc, Ltd, LLC, GmbH & Co. KG.
- Keep level words (Senior, Junior, Lead). Never merge different cities.
- Different ID hit: write `⚠️ possible duplicate`; add `⚠️ possibly applied MM-DD` when the other posting was applied to.
- Annotate only; never delete, reclassify or merge counts.

Cross-source dedup (`common.dedupe.crossSource` / `.skipApplied`, default `true`):

- Before opening a card on a platform, look up its normalized key in today's application log. When that entry belongs to another platform, skip the card and count it as **applied on another platform (skipped)**. It never becomes a match, review or excluded row, and `job-apply` must never file it again.
- A cross-source hit that is not applied stays eligible; write `⚠️ same job on <other source>` in Notes and keep both rows only when they are genuinely different postings.
- With `skipApplied: false`, cross-source duplicates are still annotated but not skipped.

## 2. Record applications

Triggers: the user says they applied, names the jobs, or `job-apply` confirms a submit.

1. Find the job in the current run's report, then earlier run reports, then today's application log by URL or company + title.
2. Append one row to `reports/applications/YYYY-MM-DD.md` (create it when missing, merge, never delete rows):

```markdown
# Applications — YYYY-MM-DD

| # | Company | Title | ATS | Status | Filled at | Link | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Example GmbH | Senior Frontend Engineer | Greenhouse | Submitted | 21:48 | [Open](applyUrl) | confirmation page shown |
```

Status values: `Inspected`, `Filled (awaiting submit)`, `Submitted`, `Blocked`, `Failed`, `Skipped`. Never write a candidate value or a guessed answer.

3. If the job is in the current run's report, append `[applied MM-DD HH:MM]` to its Notes.
4. If ambiguous, ask one question. Never guess or mark a batch.
5. Do not change report counts or decisions.

## 3. Audit schema

Path: `reports/runs/YYYY-MM-DD.jsonl`. Append one line per run; never overwrite.

```json
{
  "runAt": "2026-11-20T21:01:00+08:00",
  "finishedAt": "2026-11-20T21:51:23+08:00",
  "durationSeconds": "<N>",
  "reportPath": "reports/daily/2026-11-20/2026-11-20-2101/report.md",
  "scope": { "countries": ["Germany"], "locations": [] },
  "sources": ["LinkedIn"],
  "queryVerbatim": true,
  "uiFiltersVerified": true,
  "queriesBySource": {
    "LinkedIn": ["<search title>", "…"]
  },
  "jobAudit": {
    "cardsCollected": "<N>",
    "mergedUnique": "<N>",
    "shallowFiltered": "<N>",
    "sentToJdReview": "<N>"
  },
  "uiFilters": {
    "LinkedIn": { "datePosted": "Past 24 hours", "employmentTypes": ["Full-time"], "workModes": [], "seniority": null }
  },
  "resultsBySource": { "LinkedIn": "<N>" },
  "resultCount": "<N>",
  "resultPagesOpened": "<N>",
  "resultPagesBySource": { "LinkedIn": "<N>" },
  "searchedBySource": { "LinkedIn": "completed", "Indeed": "skipped (not scheduled today)" },
  "cardsSkipped": "<N>",
  "postingsInspected": "<N>",
  "applyFormsInspected": "<N>",
  "applyBlocked": "<N>",
  "saved": "<N>",
  "savedAlready": "<N>",
  "saveFailed": "<N>",
  "expired": "<N>",
  "appliedSkipped": "<N>",
  "appliedElsewhereSkipped": "<N>",
  "previouslyReportedSkipped": "<N>",
  "matched": "<N>",
  "matchedBySource": { "LinkedIn": "<N>" },
  "thirdPartyMatched": "<N>",
  "germanJdDeferred": "<N>",
  "review": "<N>",
  "excluded": "<N>",
  "crossSourceDuplicates": "<N>",
  "crossDayRepeats": "<N>",
  "possibleDuplicates": "<N>",
  "stopReason": "<short phrase>",
  "limitations": []
}
```

**This block is a schema, not a record.** Every `<N>` is a placeholder for this run's real value.

Rules:

- `runAt` = search start; `finishedAt` = report and audit finished; `durationSeconds` = integer difference.
- Use local time with UTC offset. Write `null` when unknown; never estimate.
- **Never write `finishedAt` or `durationSeconds` before the run has actually finished.**
- `reportPath` = this run's report file, exactly as written and published.
- `sources` = platforms attempted in this run, in order. A platform whose schedule is not due today is **not** attempted: leave it out of `sources` and write `searchedBySource.<name>` = `skipped (not scheduled today)`.
- `queriesBySource` = the search titles actually submitted, per source, in order.
- `queryVerbatim` = `true` only when each submitted title was read back and matched its configured string.
- `uiFiltersVerified` = `true` only when every configured filter was confirmed active before reading results.
- `jobAudit` = the step-1 funnel from the report.
- `resultsBySource` / `resultCount` = the count the platform displayed; `null` when absent.
- `matched` / `review` / `excluded` are this run's counts. Never write a day total.
- `appliedSkipped` = jobs in today's log for the same platform; `appliedElsewhereSkipped` = cards skipped because another platform already had the application; `previouslyReportedSkipped` = cards found in the previous run's `job-audit.md` merged list (fallback: its report tables).
- `saved` = matched rows whose Save click was verified this run; `savedAlready` = matched rows already in the saved list and left untouched; `saveFailed` = matched rows recorded as `not saved: <reason>`. All three are `0` when `common.saveMatchedJobs` is not `true`.
- `thirdPartyMatched` is a subset of `matched`.
- `germanJdDeferred` = postings whose title gate passed and whose JD is German, written to `<run>/german-jd-audit.md` and excluded from every Part 1 table (`germanJdPass.enabled` must be `true`, else `0`). Part 2's own counts live in `<run>/both-lan.md`, not in this line.
- `limitations`: only actual limitations; empty on a normal run.

## 4. Retention

Never delete audit lines automatically. Export, clean or rebuild only when the user asks and confirms the scope.
