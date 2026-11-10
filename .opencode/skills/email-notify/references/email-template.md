# Run summary email template

This document is the **single content baseline** for every email sent by the `email-notify` skill. Read it before sending. Never add fields, turn it into a job list, or attach detailed data.

## Principles

- Send a summary only; never job details.
- Never include company names, job titles, URLs, JD text, match scores or recommendations.
- Body in `preferredReportLanguage` from `job-hunter.config.json` (default `English`); the subject stays ASCII and English.
- Keep every email under 20 lines.
- **Distinguish "day total" from "this run"**: the daily report is a cumulative snapshot of the day, while this run may only have opened a few new jobs.
- All numbers come from today's daily-report summary table and the latest audit entry; write `cannot determine` when unknown, and never estimate.

## Subject

The subject is not translated: keep the ASCII tokens `[Job Hunter]`, `<status>`, `matched` and the date as shown.

```text
[Job Hunter] YYYY-MM-DD <status> · <matched> matched
```

- `<status>`: `ok` / `partial` / `failed`
- `<matched>` is the **day-total match count** (the "Matched" row of the daily-report summary), not this run's new count
- Write `no data` when no number is available
- Example: `[Job Hunter] 2026-11-10 ok · 28 matched`

## Body

Write every label and status line in `preferredReportLanguage`, and keep dates, times, numbers, `reports/...` paths and the `HH:MM` format unchanged. The English example below is the reference layout; translate only the human-readable text.

```text
Job Hunter daily search summary

Date: 2026-11-10
Run time: 14:05 – 14:14 (9 min)
Scope: Germany (nationwide)
Day total: inspected 135 · matched 28 · review 12 · excluded 95
This run: inspected 5 · matched 0 · excluded 5
Skipped as applied: 0
Stop reason: no more result pages (127 cards read)
Report: reports/daily/2026-11-10.md

Status: completed normally
```

Field sources and rules:

| Line | Source | Rule |
|---|---|---|
| Date | audit `runAt` | `YYYY-MM-DD` |
| Run time | audit `runAt` / `finishedAt` / `durationSeconds` | `HH:MM – HH:MM (N min)`; if the end time is missing, show only the start; omit the parentheses without a duration |
| Scope | audit `scope.countries` / `scope.locations` | With no `locations`, write `(nationwide)`; otherwise list cities, at most five, then "etc." |
| Day total | daily report run-summary table | inspected = `JDs read successfully`, matched = `Matched`, review = `Needs manual review`, excluded = `Confirmed non-match (excluded)` |
| This run | audit | `postingsInspected` / `matched` / `excluded` |
| Skipped as applied | audit `appliedSkipped` | write 0 when absent |
| Stop reason | audit `stopReason` | One short English phrase; write `not recorded` when absent |
| Report | fixed path | `reports/daily/YYYY-MM-DD.md` |
| Status | run outcome | see the table below; translate the wording into `preferredReportLanguage` |

When the daily-report summary is missing or unreadable, keep only the "This run" line and omit "Day total".

## Status wording

Translate the wording into `preferredReportLanguage`; the subject still uses the ASCII tokens `ok` / `partial` / `failed`.

| Situation | Status |
|---|---|
| Report written, paging reached the end or covered `lookbackHours` | `completed normally` |
| Result pages left unread, some pages unreadable, filters could not be applied | `partial: <one-line reason>` |
| Login, CAPTCHA, browser unavailable, report not written | `failed: <one-line reason>` |

**Reusing jobs already judged earlier in the day and only opening a few new ones is a normal completion, not a partial run.** Only an incomplete coverage counts as `partial`.

The subject's `<status>` maps to `ok` / `partial` / `failed`, independent of the body language.

## Forbidden content

- Job lists, company names, job titles, links, salaries, JD fragments
- Match scores, recommendation levels, candidate assessments
- SMTP password, cookies, session tokens, browser data
- Logs or error stack traces longer than 20 lines

## Failure email

When complete statistics cannot be produced, send only the following layout, with the labels translated into `preferredReportLanguage`:

```text
Job Hunter run failed

Date: 2026-11-10
Failed stage: search / read JD / write report
Reason: <one line>
Kept: reports/daily/2026-11-10.md (if already written)

Status: failed
```
