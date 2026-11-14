# Job-search email template

Use for job-search run summaries only. Keep the body under 20 lines.

## Subject

```text
[Job Hunter] YYYY-MM-DD <status> · <matched> matched
```

- `<status>`: `ok` / `partial` / `failed`.
- `<matched>`: the day-total `Matched` count, or `no data`.
- Keep the subject ASCII and English.

## Body

Write labels in `preferredReportLanguage`; keep dates, times, numbers, paths and `HH:MM` unchanged.

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

Field sources:

| Line | Source | Rule |
|---|---|---|
| Date | audit `runAt` | `YYYY-MM-DD` |
| Run time | audit `runAt` / `finishedAt` / `durationSeconds` | `HH:MM – HH:MM (N min)`; omit the end or duration when missing |
| Scope | audit `scope.countries` / `locations` | No `locations` = `(nationwide)`; list up to five cities, then "etc." |
| Day total | daily report run summary | inspected = `JDs read successfully`, matched = `Matched`, review = `Needs manual review`, excluded = `Confirmed non-match (excluded)` |
| This run | audit | `postingsInspected` / `matched` / `excluded` |
| Skipped as applied | audit `appliedSkipped` | `0` when absent |
| Stop reason | audit `stopReason` | One short phrase; `not recorded` when absent |
| Report | fixed path | `reports/daily/YYYY-MM-DD.md` |

Omit the day-total line when the summary is missing or unreadable.

## Status

- `completed normally`: report written and paging covered `lookbackHours`.
- `partial: <reason>`: pages left unread, pages unreadable, or filters unavailable.
- `failed: <reason>`: login, CAPTCHA, browser unavailable, or no report.

## Forbidden

- Job lists, company names, titles, links, salaries, JD fragments.
- Scores, recommendations, candidate assessments.
- SMTP password, cookies, session tokens, browser data.
- Logs longer than 20 lines.

## Failure email

```text
Job Hunter run failed

Date: 2026-11-10
Failed stage: search / read JD / write report
Reason: <one line>
Kept: reports/daily/2026-11-10.md (if written)

Status: failed
```
