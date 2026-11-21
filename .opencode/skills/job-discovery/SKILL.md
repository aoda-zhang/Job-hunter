---
name: job-discovery
description: Search each configured job title on the platforms in sources with the local browser, record every result card in a job-audit list, merge and shallow-filter titles, then inspect real JDs and write the daily report. Three steps, each with its own reference document.
---

# Job Discovery

Run locally in this repository with the configured browser tools. No backend, database, CLI, CI or source adapters.

**One run = one report file**: `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/report.md` (`HHMM` = start time, `-2` / `-3` on collision). Never append to or rewrite another run's file and never write a day total.

## 1. Read config

Read `job-hunter.config.json` (Git-ignored). Never use the example as personal settings; if it is missing, tell the user to copy it and stop.

- `sources` — platform list **and run order**; each entry needs a `platforms.<name>` block.
- `common.searchTitles` — ordered titles, **one query per entry**. Required; stop and ask when empty.
- `common.countries` / `common.locations` — scope. Empty `locations` = the whole country.
- `common.lookbackHours`, `workModes`, `employmentTypes`, `seniority.include` — scope and filters.
- `common.jobTitles.include`, `jdLanguages.*`, `technicalKeywords.*` — **matching only, never queries**.
- `common.thirdPartyPostings`, `dedupe.*`, `report.*`, `sortBy`, `preferredReportLanguage`, `reportRepo`, `isNeededCover`.
- `platforms.<name>.search.queryMode` — `titles` (default) or `custom`. **There is no prompt mode.**

`applicant`, `applications` and `notifications` are runtime blocks; `schedules.*` never changes how a run searches.

## 2. Prepare the run

Read these once, before the first platform:

- **previous-run set** — job IDs and canonical URLs in the single most recent earlier report (same or previous day). Those cards are skipped and recorded only in `job-audit`.
- **known set** — index jobs with status `matched` or `review`, keyed by normalized `company + title + city`; used for duplicate annotations only.
- **applied set** — index entries with `appliedOn`, extended during the run.

Scope: require one non-empty `common.countries`; non-empty `locations` limits to those cities. Never narrow silently.

Cross-source rules (`common.dedupe`):

- `crossSource: true` — the same `company + title + city` on two platforms is one vacancy: keep the first row, annotate the second `⚠️ same job on <source>`. Never merge rows or change a decision.
- `skipApplied: true` — a vacancy applied to on another platform is never opened or applied to again; it is shown only in `job-audit` as `applied on another platform (skipped)`.
- Extend the applied set as applications are confirmed, so a later platform sees them.
- With `crossSource: false`, only canonical URL / job ID dedupe applies.

## 3. The three steps

| Step | Document | Produces |
|---|---|---|
| **1 · Collect** | `references/step-1-collect.md` | `job-audit`: every card — company, title, link, job ID |
| **2 · Merge and shallow-filter** | `references/step-2-merge-filter.md` | one row per vacancy + who survives to step 3 |
| **3 · JD review** | `references/step-3-jd-review.md` | matched / review / excluded, apply fields, cover letters |

Run them in this order; never merge or reorder them. Step 1 finishes every source before step 2 starts. Step 3 opens exactly one posting at a time.

Platform mechanics live in `references/linkedin.md` and `references/indeed.md`; report structure lives in `references/daily-report-format.md`; index and audit fields in `references/job-index-and-audit.md`.

## 4. Rules for every step

- **Strictly sequential**: one query, one posting, one tab. Never batch-open cards or URLs, never loop over job IDs inside one call or script, never keep more than one job tab open.
- Search results are not evidence: recommendation and fallback blocks ignore the filters. Judge every posting from its own page.
- One source failure does not stop the run: record it in `limitations` and `searchedBySource`, continue, report it.
- **Stop-all**: `verify you are human`, CAPTCHA, `unusual activity` / `unusual traffic`, `automated access`, `are you a robot`, an AI-agent warning, or a forced re-login/2FA stops the entire run immediately — no navigation, search, apply or retry. Keep what is written and tell the user to take over.
- **Language split**: the report and the summary email follow `common.preferredReportLanguage`; every value sent to an employer — form fields, free-text answers, cover letters, uploaded documents — is **English only**, whatever that setting says.
- Never fabricate a listing, JD fact, field value or result. Never guess a private API or bypass access controls.
- Discovery never fills or submits a platform one-click apply; it may open it once read-only to record fields.

## 5. Outputs

1. **Report** — this run's file, in `common.preferredReportLanguage`, following `references/daily-report-format.md`: run header, `job-audit`, matched, review, excluded.
2. **Index** — upsert every inspected vacancy in `reports/job-index.json`; never clear `appliedOn` or any `apply*` field.
3. **Audit** — append one JSON line to `reports/runs/YYYY-MM-DD.jsonl` with real `runAt`, `finishedAt`, `durationSeconds`, `reportPath` and the fields in `references/job-index-and-audit.md`. Never write `finishedAt` in advance.
4. **Publish** — when `reportRepo` is set, push only the run folder. Never publish the index, runs or applications.
5. **Apply** — when `applications.enabled` is `true`, load `job-apply` after the report and index are written.
6. **Email** — when `notifications.email.enabled` is `true`, send one summary via `email-notify`.

Report completion: report path and start time, scope, titles submitted, the step-1 funnel, skips, matched / Easy Apply / No Easy Apply, applications filled / submitted / blocked, third-party postings, review, excluded, coverage and stop reason per source, email status, limitations.
