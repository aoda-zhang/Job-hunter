# Job index and run audit

Local memory layer. Follow this on every `job-discovery` run. Never push these files to `reportRepo`.

## 1. Files

| File | Purpose |
|---|---|
| `reports/job-index.json` | Cross-day index and application record |
| `reports/runs/YYYY-MM-DD.jsonl` | Run audit, one line per run |

Both are Git-ignored and local only.

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
      "posterType": "direct",
      "business": "",
      "note": ""
    }
  }
}
```

Rules:

- Key: `<source>:<jobId>`, e.g. `LinkedIn:4487182341`, `Indeed:7f3c9a1b2d4e5f60`.
- With no job ID, use `source + canonical URL`; one URL = one entry.
- Treat legacy bare IDs as LinkedIn; keep their keys.
- `source`: canonical name (`LinkedIn`, `Indeed`, `Glassdoor`), not a domain alias.
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
- `posterType`: `direct` / `third_party` / `unknown` from the posting; treat missing legacy values as `unknown`.
- `business`: short phrase only when the JD explicitly states the company's product, market or industry; otherwise `""`. For `third_party`, it describes the client employer.
- `note`: verifiable page facts only; no judgment.
- Update only relevant fields; preserve unknown fields and other entries.

Create the index when missing. If unparseable, back it up to `reports/job-index.json.bak`, start empty, and say so.

## 3. Read order

1. `reports/job-index.json`.
2. If missing, bootstrap from the previous 7 `reports/daily/` dates: URLs, status, first-seen.
3. If neither exists, start empty.

## 4. Dedup

Hard dedup: same job ID or canonical URL on one platform; same canonical URL across platforms.

- `appliedOn` set: do not open, judge or list. Count as "Already applied (skipped)".
- `matched` / `review`: reopen and judge today; append `[reported MM-DD]` from `firstReportedOn`.
- `excluded` / `expired`: re-evaluate; no repeat marker. If it matches today, set `firstReportedOn` to today.

Soft dedup: compare `normalized company + normalized title + city`, without the platform name.

- Normalize: lowercase; strip punctuation, extra spaces, `(m/w/d)`, `(f/m/d)`, `(all genders)`, and GmbH, AG, SE, Inc, Ltd, LLC, GmbH & Co. KG.
- Keep level words (Senior, Junior, Lead). Never merge different cities.
- Different ID hit: write `⚠️ possible duplicate`; add `⚠️ possibly applied MM-DD` when the other posting was applied to.
- Annotate only; never delete, reclassify or merge counts.

## 5. Record applications

Triggers: the user says they applied, names the jobs, or `job-apply` confirms a submit.

1. Find the job in today's report, historical reports, then the index by URL or company + title.
2. Set `appliedOn` to today; keep `status`.
3. If it is in today's report, append `[applied MM-DD]` to Notes; otherwise update the index only.
4. If ambiguous, ask one question. Never guess or mark a batch.
5. Do not change report counts or decisions.
6. `job-apply` also writes `applyType`, `applyStatus`, `applyChannel`, `applyUrl`, `applyAttemptedAt`, `applicationRef` and `applyNote`. Only a confirmed submit sets `appliedOn`; a filled-but-unsubmitted form stays `applyStatus: "filled"` with `appliedOn: null`.

## 6. Audit schema

Path: `reports/runs/YYYY-MM-DD.jsonl`. Append one line per run; never overwrite.

```json
{
  "runAt": "2026-11-10T09:30:00+01:00",
  "finishedAt": "2026-11-10T10:02:00+01:00",
  "durationSeconds": 1920,
  "scope": { "countries": ["Germany"], "locations": [] },
  "sources": ["LinkedIn"],
  "uiFilters": { "LinkedIn": { "datePosted": "Past 24 hours", "employmentTypes": ["Full-time"], "workModes": ["Remote", "Hybrid", "On-site"], "seniority": null } },
  "prompt": "…verbatim jobSearchPrompt…",
  "resultsBySource": { "LinkedIn": 300 },
  "resultCount": 300,
  "resultPagesOpened": 5,
  "resultPagesBySource": { "LinkedIn": 5 },
  "searchedBySource": { "LinkedIn": "completed" },
  "cardsSkipped": 0,
  "postingsInspected": 120,
  "expired": 0,
  "appliedSkipped": 4,
  "matched": 23,
  "thirdPartyMatched": 5,
  "review": 12,
  "excluded": 85,
  "crossDayRepeats": 10,
  "possibleDuplicates": 2,
  "stopReason": "results older than lookbackHours",
  "limitations": []
}
```

Rules:

- `runAt` = search start; `finishedAt` = report, index and audit finished; `durationSeconds` = integer difference.
- Use local time with UTC offset. Write `null` when unknown; never estimate.
- `sources` = platforms attempted, in order. `searchedBySource` = `completed` / `failed` / `skipped` with reason.
- `uiFilters` = only filters the platform offered; otherwise `{}`.
- `resultsBySource` / `resultCount` = page count; `null` when absent. Page counts go in `resultPagesBySource`; `resultPagesOpened` = total.
- Older `linkedinResultCount` equals `resultsBySource.LinkedIn`; read compatibly, never rewrite.
- `stopReason`: short phrase, e.g. `results older than lookbackHours`, `no more pages`, `login required`.
- `limitations`: only actual limitations; empty on a normal run.
- `postingsInspected` / `matched` / `review` / `excluded` are this run's counts. The report summary is the day total; never conflate them.
- `thirdPartyMatched` is a subset of `matched` (the `代招岗位` rows), not an additional count.

## 7. Retention

Never delete entries or audit lines automatically. Export, clean or rebuild only when the user asks and confirms the scope.
