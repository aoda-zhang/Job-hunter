# Feed email template

Use for LinkedIn feed passes only.

## Subject

```text
[Job Hunter] YYYY-MM-DD feed · N comments · M jobs
```

`N` = selected comment opportunities, `M` = feed-sourced job rows. Use `0 comments` / `0 jobs` when none.

## Body

Write labels in `common.preferredReportLanguage`; keep dates, times, URLs, paths and numbers unchanged.

```text
LinkedIn comment search results

Date: 2026-11-14
Window: past 24 hours · Germany · frontend / Node.js fullstack
Posts reviewed: 48 · comment opportunities: 3 · feed jobs: 2

## Comments

1. Jane Doe — Senior Frontend Engineer
Link: https://www.linkedin.com/posts/...
Primary comment: <question-led comment, ready to send>
Backup comment: <add-on comment, ready to send>

2. John Smith — Tech Lead
Link: ...
Primary comment: ...
Backup comment: ...

## Feed-sourced jobs

1. Example GmbH — Senior Frontend Engineer — Berlin — Hybrid
   Link: https://www.linkedin.com/posts/...
2. Another GmbH — React Developer — Remote (Germany)
   Link: https://www.linkedin.com/posts/...

Reports:
- reports/linkedin-feed/2026-11-14.md
- reports/daily/2026-11-14/2026-11-14.md

Status: completed normally
```

Write `No post met the comment bar.` under `## Comments` and `No matching feed jobs.` under `## Feed-sourced jobs` when empty. Keep both headings. Add the daily report path only when job rows were added.

## Field rules

| Field | Source | Rule |
|---|---|---|
| Date | run date | `YYYY-MM-DD` |
| Window | config | `past <lookbackHours> hours` · scope · topics |
| Posts reviewed | search summary | posts actually rendered |
| Comment opportunities | search summary | selected comments |
| Feed jobs | daily report | rows added in this run |
| Author / headline | comment checklist | keep unchanged |
| Link | comment checklist | copied permalink or `Link unavailable` |
| Primary comment / Backup comment | comment checklist | copy-ready text, no labels or links inside |
| Job row | daily report | company, title, location, mode, permalink |
| Reports | fixed paths | feed report always; daily report only with job rows |
| Status | run outcome | `completed normally` / `partial: <reason>` / `failed: <reason>` |

## Status

- `completed normally`: both reports written and the comment search finished within the cap.
- `partial: <reason>`: pages left unread, search stopped early, or filters unavailable.
- `failed: <reason>`: login wall, CAPTCHA, browser unavailable, or no report.

## Forbidden

- SMTP password, cookies, session tokens, browser data.
- Fabricated posts, jobs, permalinks, metrics.
- Anything implying the user commented, replied or applied.
- Logs longer than 20 lines.
