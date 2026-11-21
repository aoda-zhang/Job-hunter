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

Write labels in `common.preferredReportLanguage`; keep dates, times, numbers, paths and `HH:MM` unchanged.

```text
Job Hunter daily search summary

Date: 2026-11-10
Run time: 14:05 – 14:14 (9 min)
Scope: Germany (nationwide)
This run: inspected 61 · matched 18 · review 0 · excluded 43
Skipped as applied: 0
Stop reason: no more result pages (127 cards read)
Report: reports/daily/2026-11-10/2026-11-10-2130.md

Status: completed normally
```

Field sources:

| Line | Source | Rule |
|---|---|---|
| Date | audit `runAt` | `YYYY-MM-DD` |
| Run time | audit `runAt` / `finishedAt` / `durationSeconds` | `HH:MM – HH:MM (N min)`; omit the end or duration when missing |
| Scope | audit `scope.countries` / `locations` | No `locations` = `(nationwide)`; list up to five cities, then "etc." |
| This run's totals | this run's report run summary | inspected = `检查 JD`, matched = `匹配`, review = `需要人工复核`, excluded = `已排除`; one run only, never a day total |
| This run (audit) | audit | `postingsInspected` / `matched` / `excluded` |
| Skipped as applied | audit `appliedSkipped` | `0` when absent |
| Stop reason | audit `stopReason` | One short phrase; `not recorded` when absent |
| Report | this run's file | `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/report.md` |

One email per run. Never sum several runs of the same day into one email.

## Status

- `completed normally`: report written and paging covered `common.lookbackHours`.
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
Kept: reports/daily/2026-11-10/2026-11-10-2130.md (if written)

Status: failed
```
