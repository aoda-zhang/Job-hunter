# Job index, deduplication and run audit

This document defines Job Hunter's local memory layer. The `job-discovery` skill must follow it on every run; the daily report structure still follows `daily-report-format.md`.

## 1. Files

| File | Purpose | Committed |
|---|---|---|
| `reports/job-index.json` | Cross-day job index and application record | No — Git-ignored, local only |
| `reports/runs/YYYY-MM-DD.jsonl` | Run audit log, one line per run | No — Git-ignored, local only |

Never push these two files to `reportRepo`. `reportRepo` receives only the day's daily report.

## 2. Job index schema

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
      "coverLetter": "unknown",
      "note": ""
    }
  }
}
```

Field rules:

- Keys use `<source>:<jobId>`, e.g. `LinkedIn:4487182341`, `Indeed:7f3c9a1b2d4e5f60`. `source` must match the platform name in `sources`.
- When the platform exposes no job ID, fall back to `source + canonical URL` as the key; one URL yields exactly one entry.
- Bare job IDs in an older index are treated as LinkedIn. Keep their keys as they are; do not rewrite them in bulk.
- `source`: the canonical platform name (`LinkedIn`, `Indeed`, `Glassdoor`), not a configured domain alias; this keeps `glassdoor.de` and `Glassdoor` from creating two entries.
- `status`: `matched` / `review` / `excluded` / `expired`, recording the **most recent** decision.
- `firstSeen`: the date the job was first opened.
- `lastSeen`: the date it was most recently opened or re-confirmed.
- `firstReportedOn`: the date it first entered the **matched or review table**; `null` if it never did. Excluded days do not count.
- `appliedOn`: the date the user confirmed an application; `null` otherwise.
- `easyApply`: whether the posting offers a one-click apply path on the platform (`yes`, `no`, `unknown`). Read from the job page only; never infer from applicant count, search ranking or JD text.
- `coverLetter`: whether the posting requires a cover letter (`yes`, `no`, `unknown`). Read from the job page or application form only; never infer from company size or industry.
- `note`: optional, verifiable facts from the page only, no judgment.
- Update only the relevant fields and preserve unknown fields; never rewrite the whole object or touch other entries.

Create the index when missing. When it cannot be parsed, back it up to `reports/job-index.json.bak`, rebuild an empty index, and say so in the run's chat output.

## 3. Read order

1. Prefer `reports/job-index.json`; it covers all history.
2. When the index is missing, read the previous 7 local dates under `reports/daily/` as a one-time bootstrap and recover only URLs, status and first-seen dates.
3. When neither exists, start from an empty index.

## 4. Deduplication and reuse rules

**Hard dedup**: the same job ID or canonical URL on one platform is the same job; an identical canonical URL across platforms is also treated as the same job.

- `appliedOn` is set in the index → **do not open, do not judge, do not list in any job table**; count it only as "Already applied (skipped)".
- Entry exists with latest status `matched` / `review` → still reopen and judge it today (it may have closed or changed), and append `[reported MM-DD]` to Notes using `firstReportedOn`.
- Entry exists with latest status `excluded` / `expired` → re-evaluate today as usual, add no `[reported]` marker; if it matches today, set `firstReportedOn` to today.

**Soft dedup (likely same role, different ID)**: the same role often has multiple job IDs, multi-city versions or bilingual versions on one platform, and is often listed on several platforms.

- Comparison key: `normalized company + normalized title + city`. When comparing across platforms, **do not** include the platform name in the key.
- Normalization: lowercase; strip punctuation, extra spaces and gender markers such as `(m/w/d)`, `(f/m/d)`, `(all genders)`; strip legal suffixes (GmbH, AG, SE, Inc, Ltd, LLC, GmbH & Co. KG).
- Do not strip level words such as Senior / Junior / Lead, and do not merge different cities.
- On a soft-dedup hit with a different job ID → write `⚠️ possible duplicate` in Notes; when the other posting has `appliedOn`, write `⚠️ possibly applied MM-DD`.
- Annotate only — never delete, reclassify or merge counts.

## 5. Application recording

Trigger: the user says "I applied to X", "mark these as applied", or names the jobs explicitly.

1. Locate the job: prefer today's report, then historical reports, then the index by URL or "company + title".
2. Set `appliedOn` to today and keep `status` unchanged.
3. If the job already appears in today's report, append `[applied MM-DD]` to Notes; otherwise update the index only.
4. When it cannot be identified uniquely, ask one clarifying question. Never guess and never mark a batch.
5. Do not change the daily report's counts or decisions.

## 6. Run audit schema

Path: `reports/runs/YYYY-MM-DD.jsonl` (split by local date; several runs in one day append several lines, never overwrite).

```json
{
  "runAt": "2026-11-10T09:30:00+01:00",
  "finishedAt": "2026-11-10T10:02:00+01:00",
  "durationSeconds": 1920,
  "scope": { "countries": ["Germany"], "locations": [] },
  "sources": ["LinkedIn"],
  "uiFilters": {
    "LinkedIn": {
      "datePosted": "Past 24 hours",
      "employmentTypes": ["Full-time"],
      "workModes": ["Remote", "Hybrid", "On-site"],
      "seniority": null
    }
  },
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
  "review": 12,
  "excluded": 85,
  "crossDayRepeats": 10,
  "possibleDuplicates": 2,
  "stopReason": "results older than lookbackHours",
  "limitations": []
}
```

Rules:

- `runAt` is when the search **started**, not when the report was written; `finishedAt` is when the report, index and audit were finished; `durationSeconds` is their integer difference.
- All three use the local time zone with a UTC offset (e.g. `+08:00`). Write `null` when unknown; never estimate.
- Record only numbers the browser session can support; write `null` when unknown, never estimate.
- `sources` records the platforms actually attempted, in configured order; `searchedBySource` marks each platform `completed` / `failed` / `skipped` (with the reason).
- `uiFilters` is grouped by platform and records only the filters that platform actually offered; a platform without UI filters gets an empty object.
- `resultsBySource` and `resultCount` come from the count the results page displays; write `null` when it shows none. Page counts go into `resultPagesBySource`; `resultPagesOpened` is the total. Older logs used `linkedinResultCount`, which equals today's `resultsBySource.LinkedIn` — read old data compatibly and never rewrite old lines.
- `stopReason` is a short phrase explaining why paging stopped, e.g. `results older than lookbackHours`, `no more pages`, `login required`, `cap reached`.
- `limitations` lists only limitations that actually occurred (CAPTCHA, rate limit, filter that could not be applied, …); empty on a normal run.
- Several runs on one day append several lines; never merge them.
- `postingsInspected` / `matched` / `review` / `excluded` are **this run's** counts; the daily report's run-summary table is the **day total**. The summary email needs both; never conflate them.

## 7. Retention and cleanup

- Never delete index entries or audit logs automatically.
- Only export, clean or rebuild when the user asks, and confirm the scope first.
