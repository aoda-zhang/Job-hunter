---
name: job-discovery
description: Search each configured job title on the platforms in sources with the local browser, record every result card in a job-audit list, merge and shallow-filter titles, then inspect real JDs and write the daily report. Three steps, each with its own reference document.
---

# Job Discovery

Run locally in this repository with the configured browser tools. No backend, database, CLI, CI or source adapters.

**One run = one report file**: `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/report.md` (`HHMM` = start time, `-2` / `-3` on collision). Never append to or rewrite another run's file and never write a day total.

## 1. Read config

Read `job-hunter.config.json` (Git-ignored). Never use the example as personal settings; if it is missing, tell the user to copy it and stop.

- `sources` — platform list **and order**; each entry needs a `platforms.<name>` block. It is not an unconditional run list: which platforms run is decided by `schedules` (§1.1).
- `common.searchTitles` — ordered titles, **one query per entry**. Required; stop and ask when empty.
- `common.countries` / `common.locations` — scope. Empty `locations` = the whole country.
- `common.lookbackHours`, `workModes`, `employmentTypes`, `seniority.include` — scope and filters.
- `common.jobTitles.include`, `jdLanguages.*`, `technicalKeywords.*` — **matching only, never queries**.
- `common.jobTitles.shallowExclude` — optional string array; a title containing any of these strings (case-insensitive) is removed in step 2 before any JD is opened, unless the normalized/translated title also contains a `jobTitles.include` phrase (that guard always wins).
- `common.jobTitles.earlyStrictMatch` — when `true`, step 2 also applies the strict title gate: a normalized/translated title without an include phrase (or with an exclude word) is removed before any JD is opened.
- `common.thirdPartyPostings`, `dedupe.*`, `report.*`, `sortBy`, `preferredReportLanguage`, `reportRepo`, `isNeededCover`.
- `platforms.<name>.search.queryMode` — `titles` (default) or `custom`. **There is no prompt mode.**

`applicant`, `applications` and `notifications` are runtime blocks.

### 1.1 Which platforms run comes from `schedules`, not `sources`

`sources` lists the configured platforms and their order. It is **not** a list every run must walk. Resolve this run's platform set before step 1:

1. Find the schedule block that triggered the run:
   - `schedules.linkedinJobSearch` → the LinkedIn job search. It covers every platform in `sources` that has **no** dedicated `<platform>JobSearch` block.
   - `schedules.indeedJobSearch` → `Indeed` only.
   - `schedules.linkedinFeedReview` → feed review only; it never runs job discovery.
2. For a manual request ("run today"), use today's local weekday (`0` and `7` are Sunday, `1` Monday … `6` Saturday) and include a platform only when its schedule block's `weekdays` contain today. A missing or empty `weekdays` means every day. `times` is advisory for a manual run (off-time is fine on a due day) and exact for a scheduled run. Platforms share a block only when they have no dedicated block of their own.
3. A platform whose schedule is not due today is not searched, not collected and not listed in the job-audit. Record it in the report header and in `searchedBySource` as `skipped (not scheduled today)`.
4. Only an explicit user request naming a platform ("also run Indeed today") may run it off-schedule; note that override in `limitations`.
5. Process the selected platforms in `sources` order. If no platform is due, stop and tell the user instead of searching one anyway.

`schedules.*` decides **which** platforms run; it never changes queries, filters, matching or reporting. With a single platform due, the report has one matched section and no empty section for the skipped one.

## 2. Prepare the run

Read these once, before the first platform:

- **previous-run set** — job IDs and canonical URLs in the single most recent earlier report (same or previous day). Those cards are skipped and recorded only in `job-audit`.
- **applied set** — every application row in today's `reports/applications/YYYY-MM-DD.md`, keyed by normalized `company + title + city`; extended as this run applies. `reports/job-index.json` is legacy and is never read or written.

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

Platform mechanics live in `references/linkedin.md` and `references/indeed.md`; report structure lives in `references/daily-report-format.md`; run-log and audit fields in `references/job-index-and-audit.md`.

## 4. Rules for every step

- **Strictly sequential**: one query, one posting, one tab. Never batch-open cards or URLs, never loop over job IDs inside one call or script, never keep more than one job tab open.
- Search results are not evidence: recommendation and fallback blocks ignore the filters. Judge every posting from its own page.
- One source failure does not stop the run: record it in `limitations` and `searchedBySource`, continue, report it.
- **Stop-all**: `verify you are human`, CAPTCHA, `unusual activity` / `unusual traffic`, `automated access`, `are you a robot`, an AI-agent warning, or a forced re-login/2FA stops the entire run immediately — no navigation, search, apply or retry. Keep what is written and tell the user to take over.
- **Language split**: the report and the summary email follow `common.preferredReportLanguage`; every value sent to an employer — form fields, free-text answers, cover letters, uploaded documents — is **English only**, whatever that setting says.
- Never fabricate a listing, JD fact, field value or result. Never guess a private API or bypass access controls.
- Discovery never fills or submits a platform one-click apply; it may open it once read-only to record fields.

## 5. Outputs

1. **Report** — this run's file, in `common.preferredReportLanguage`, following `references/daily-report-format.md`: run header, summary, matched, review, excluded. The step-1 record is a separate `<run>/job-audit.md`.
2. **Application log** — record every attempted application in `reports/applications/YYYY-MM-DD.md`; never write `reports/job-index.json`.
3. **Audit** — append one JSON line to `reports/runs/YYYY-MM-DD.jsonl` with real `runAt`, `finishedAt`, `durationSeconds`, `reportPath` and the fields in `references/job-index-and-audit.md`. Never write `finishedAt` in advance.
4. **Publish** — when `reportRepo` is set, push only the run folder. Never publish the index, runs or applications.
5. **Apply** — when `applications.enabled` is `true`, load `job-apply` after the report and index are written.
6. **Email** — when `notifications.email.enabled` is `true`, send one summary via `email-notify`.

Report completion: report path and start time, scope, titles submitted, the step-1 funnel, skips, matched / Easy Apply / No Easy Apply, applications filled / submitted / blocked, third-party postings, review, excluded, coverage and stop reason per source, email status, limitations.
