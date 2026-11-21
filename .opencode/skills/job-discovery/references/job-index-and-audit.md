# Job index and run audit

Local memory layer. Follow this on every `job-discovery` run. Never push these files to `common.reportRepo`.

## 1. Files

| File | Purpose |
|---|---|
| `reports/job-index.json` | Cross-day index and application record |
| `reports/runs/YYYY-MM-DD.jsonl` | Run audit, one line per run |
| `reports/applications/YYYY-MM-DD.md` | Application log, read by the pre-run apply check |

All three are Git-ignored and local only.

## 2. Index schema

```json
{
  "version": 1,
  "updatedAt": "2026-11-10",
  "jobs": {
    "LinkedIn:4487182341": {
      "jobId": "4487182341",
      "source": "LinkedIn",
      "url": "https://www.linkedin.com/jobs/view/4487182341/",
      "company": "immobilien.de",
      "title": "Senior Software Engineer",
      "city": "Berlin",
      "firstSeen": "2026-11-08",
      "lastSeen": "2026-11-10",
      "firstReportedOn": "2026-11-08",
      "status": "matched",
      "appliedOn": null,
      "easyApply": "unknown",
      "applyType": "unknown",
      "applyStatus": "not_started",
      "applyChannel": "",
      "applyUrl": "",
      "applyAttemptedAt": null,
      "applicationRef": "",
      "applyNote": "",
      "coverLetter": "unknown",
      "coverLetterDraft": "",
      "posterType": "direct",
      "business": "",
      "applyForm": "",
      "note": ""
    }
  }
}
```

Rules:

- Key: `<source>:<jobId>`, e.g. `LinkedIn:4487182341`, `Indeed:7f3c9a1b2d4e5f60`.
- With no job ID, use `source + canonical URL`; one URL = one entry.
- Treat legacy bare IDs as LinkedIn; keep their keys.
- `source`: canonical name (`LinkedIn`, `Indeed`), not a domain alias.
- `status`: `matched` / `review` / `excluded` / `expired`, latest decision.
- `firstSeen`: first opened date. `lastSeen`: latest opened or confirmed date.
- `firstReportedOn`: first date in a matched or review table; `null` otherwise.
- `appliedOn`: user-confirmed application date; `null` otherwise.
- `easyApply`: `yes` / `no` / `unknown` from the page only.
- `applyType`: `easy_apply` / `external` / `unknown`; `external` only when the button clearly leaves the platform. Never set from a guess.
- `applyStatus`: `not_started` / `filled` / `submitted` / `blocked` / `failed` / `skipped`; written by `job-apply`.
- `applyChannel`: ATS name or host actually used, e.g. `Greenhouse`, `Workday`, `Personio`; empty until an attempt.
- `applyUrl`: final third-party application URL actually opened; never assemble one.
- `applyAttemptedAt`: ISO date-time of the apply attempt; `null` before any attempt.
- `applicationRef`: confirmation number/text shown by the site; empty otherwise.
- `applyNote`: one short verifiable fact, e.g. `blocked: account creation required`; no judgment.
- `coverLetter`: `yes` / `no` / `unknown` from the page or form only.
- `coverLetterDraft`: saved path under `reports/cover-letters/`, or empty.
- `posterType`: `direct` / `third_party` / `unknown` from the posting; treat missing legacy values as `unknown`.
- `business`: short phrase only when the JD explicitly states the company's product, market or industry; otherwise `""`. For `third_party`, it describes the client employer.
- `applyForm`: `inspected` / `blocked` / `not_external`; empty when no apply form was checked. Discovery records the form read-only; it never fills or submits.
- `note`: verifiable page facts only; no judgment.
- Update only relevant fields; preserve unknown fields and other entries.

Create the index when missing. If unparseable, back it up to `reports/job-index.json.bak`, start empty, and say so.

## 3. Read order

The index is an application/history record; it is **not** a source for "already listed" decisions.

1. Read every earlier run report of today (`reports/daily/YYYY-MM-DD/YYYY-MM-DD-*.md` with an earlier `HHMM`) and every run report of the most recent previous date, for the previous-report set.
2. Read `reports/job-index.json` to preserve existing entries, to collect `appliedOn`, and to build the cross-source applied set (§4).
3. Read the last 30 days of `reports/applications/*.md` for `Submitted` / `Filled (awaiting submit)` rows and merge them into the applied set.
4. If the index is missing, create it empty; do not rebuild it from old reports for dedupe.

Record the pre-run result in the report header: applied entries checked, this run's hits, skipped count. The check runs before the first platform is opened and again before `job-apply` fills anything.

## 4. Dedup

Hard dedup: same job ID or canonical URL on one platform; same canonical URL or normalized identity across platforms.

- **Previous-report set**: at run start, read every earlier run report of today plus every run report of the most recent previous date, and extract every job ID / canonical URL from all their tables. A card in this set is not opened, not judged and not listed; count it as "Previously reported (skipped)".
- `appliedOn` jobs count as "Already applied (skipped)".
- `common.skipPreviousReport` (default `true`) enables this. The reports, not the index, drive this skip.
- Override only on explicit user request (named jobs, a company, a status); exempt those keys for that run and record the exemption in `limitations`.
- The first run of a day with no earlier report checks everything; later runs only process genuinely new postings. This is what prevents overlap from the daily `common.lookbackHours` window.

Soft dedup: compare `normalized company + normalized title + city`, without the platform name.

- Normalize: lowercase; strip punctuation, extra spaces, `(m/w/d)`, `(f/m/d)`, `(all genders)`, and GmbH, AG, SE, Inc, Ltd, LLC, GmbH & Co. KG.
- Keep level words (Senior, Junior, Lead). Never merge different cities.
- Different ID hit: write `⚠️ possible duplicate`; add `⚠️ possibly applied MM-DD` when the other posting was applied to.
- Annotate only; never delete, reclassify or merge counts.

Cross-source dedup (`common.dedupe.crossSource` / `.skipApplied`, default `true`):

- Build the applied set at run start: every index entry with `appliedOn` set or `applyStatus` in `submitted` / `filled`, plus every `Submitted` / `Filled (awaiting submit)` row in the last 30 days of `reports/applications/*.md`, mapped to the normalized key above. Do not clear or rewrite those entries.
- Before opening a card on a platform, look up its normalized key. When the applied entry belongs to another platform, skip the card and count it as **applied on another platform (skipped)**. It never becomes a match, review or excluded row, and `job-apply` must never file it again.
- A cross-source hit that is not applied stays eligible; write `⚠️ same job on <other source>` in Notes and keep both rows only when they are genuinely different postings. Same normalized key + same employer = one vacancy: keep the row of the source that appears first in `sources`.
- With `skipApplied: false`, cross-source duplicates are still annotated but not skipped.
- Platform names come from `sources`; `LinkedIn` is the canonical name, not a domain alias.

## 5. Record applications

Triggers: the user says they applied, names the jobs, or `job-apply` confirms a submit.

1. Find the job in the current run's report, then earlier run reports, then the index by URL or company + title.
2. Set `appliedOn` to today; keep `status`.
3. If it is in the current run's report, append `[applied MM-DD HH:MM]` to Notes; otherwise update the index only.
4. If ambiguous, ask one question. Never guess or mark a batch.
5. Do not change report counts or decisions.
6. `job-apply` also writes `applyType`, `applyStatus`, `applyChannel`, `applyUrl`, `applyAttemptedAt`, `applicationRef` and `applyNote`. Only a confirmed submit sets `appliedOn`; a filled-but-unsubmitted form stays `applyStatus: "filled"` with `appliedOn: null`.

## 6. Audit schema

Path: `reports/runs/YYYY-MM-DD.jsonl`. Append one line per run; never overwrite.

```json
{
  "runAt": "2026-11-20T21:01:00+08:00",
  "finishedAt": "2026-11-20T21:51:23+08:00",
  "durationSeconds": 3023,
  "reportPath": "reports/daily/2026-11-20/2026-11-20-2101.md",
  "scope": { "countries": ["Germany"], "locations": [] },
  "sources": ["LinkedIn", "Indeed"],
  "queriesBySource": {
    "LinkedIn": ["<jobSearchPrompt>"],
    "Indeed": ["Frontend Developer", "React Developer", "Fullstack Developer"]
  },
  "uiFilters": {
    "LinkedIn": { "datePosted": "Past 24 hours", "employmentTypes": ["Full-time"], "workModes": ["Remote", "Hybrid", "On-site"], "seniority": null },
    "Indeed": { "datePosted": "Last 7 days", "jt": "fulltime", "lang": null, "remote": false, "quickApply": false }
  },
  "resultsBySource": { "LinkedIn": 300, "Indeed": 75 },
  "resultCount": 375,
  "resultPagesOpened": 8,
  "resultPagesBySource": { "LinkedIn": 5, "Indeed": 3 },
  "searchedBySource": { "LinkedIn": "completed", "Indeed": "completed" },
  "cardsSkipped": 0,
  "postingsInspected": 120,
  "applyFormsInspected": 40,
  "applyBlocked": 3,
  "expired": 0,
  "appliedSkipped": 4,
  "appliedElsewhereSkipped": 2,
  "previouslyReportedSkipped": 180,
  "matched": 23,
  "matchedBySource": { "LinkedIn": 15, "Indeed": 8 },
  "thirdPartyMatched": 5,
  "review": 12,
  "excluded": 85,
  "crossSourceDuplicates": 3,
  "crossDayRepeats": 10,
  "possibleDuplicates": 2,
  "stopReason": "results older than lookbackHours",
  "limitations": []
}
```

Rules:

- `runAt` = search start; `finishedAt` = report, index and audit finished; `durationSeconds` = integer difference.
- Use local time with UTC offset. Write `null` when unknown; never estimate.
- **Never write `finishedAt` or `durationSeconds` before the run has actually finished.** Write the audit line only at the end, from the real clock; a future timestamp is a defect, not a placeholder.
- `reportPath` = this run's report file (`reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/report.md`), exactly as written and published.
- `sources` = platforms attempted, in order. `searchedBySource` = `completed` / `failed` / `skipped` with reason.
- `queriesBySource` = the queries actually submitted, per source. Keep the prompt verbatim for `queryMode: "prompt"`.
- `uiFilters` = only filters the platform offered; otherwise `{}`.
- `resultsBySource` / `resultCount` = page count; `null` when absent. Page counts go in `resultPagesBySource`; `resultPagesOpened` = total.
- Older `linkedinResultCount` equals `resultsBySource.LinkedIn`; read compatibly, never rewrite.
- `stopReason`: short phrase, e.g. `results older than lookbackHours`, `no more pages`, `login required`.
- `limitations`: only actual limitations; empty on a normal run.
- `postingsInspected` / `matched` / `review` / `excluded` are this run's counts. The report summary is the day total; never conflate them.
- `appliedSkipped` = jobs with `appliedOn` on the same platform; `appliedElsewhereSkipped` = cards skipped because another platform already had the application; `previouslyReportedSkipped` = other cards found in the previous daily report that were not opened.
- `applyFormsInspected` = matched external forms actually opened and read; `applyBlocked` = forms stopped by a login, account, CAPTCHA or unconfigured required field.
- `thirdPartyMatched` is a subset of `matched` (the `代招岗位` rows), not an additional count.
- `crossSourceDuplicates` = cross-source normalized-key hits this run; `possibleDuplicates` = same-platform soft duplicates.

## 7. Retention

Never delete entries or audit lines automatically. Export, clean or rebuild only when the user asks and confirms the scope.
