# Feed email template

Use for LinkedIn feed passes only.

## Subject

```text
[Job Hunter] YYYY-MM-DD feed · N replies · M jobs
```

`N` = selected replies, `M` = feed-sourced job rows. Use `0 replies` / `0 jobs` when none.

## Body

Write labels in `common.preferredReportLanguage`; keep dates, times, URLs, paths and numbers unchanged.

```text
LinkedIn Feed results

Date: 2026-11-14
Window: past 24 hours
Posts reviewed: 48 · reply opportunities: 5 · feed jobs: 2

## Replies

1. Jane Doe — Senior Frontend Engineer
Link: https://www.linkedin.com/posts/...
Primary: <question-led reply, ready to send>
Backup: <add-on reply, ready to send>

2. John Smith — Tech Lead
Link: ...
Primary: ...
Backup: ...

## Feed-sourced jobs

1. Example GmbH — Senior Frontend Engineer — Berlin — Hybrid
   Link: https://www.linkedin.com/posts/...
2. Another GmbH — React Developer — Remote (Germany)
   Link: https://www.linkedin.com/posts/...

Reports:
- reports/linkedin-feed/2026-11-14.md
- reports/daily/2026-11-14.md

Status: completed normally
```

Write `No post met the reply bar.` under `## Replies` and `No matching feed jobs.` under `## Feed-sourced jobs` when empty. Keep both headings. Add the daily report path only when job rows were added.

## Field rules

| Field | Source | Rule |
|---|---|---|
| Date | run date | `YYYY-MM-DD` |
| Window | config | `past <lookbackHours> hours` |
| Posts reviewed | feed summary | posts actually rendered |
| Reply opportunities | feed summary | selected replies |
| Feed jobs | daily report | rows added in this run |
| Author / headline | feed checklist | keep unchanged |
| Link | feed checklist | copied permalink or `Link unavailable` |
| Primary / Backup | feed checklist | copy-ready text, no labels or links inside |
| Job row | daily report | company, title, location, mode, permalink |
| Reports | fixed paths | feed report always; daily report only with job rows |
| Status | run outcome | `completed normally` / `partial: <reason>` / `failed: <reason>` |

## Status

- `completed normally`: both reports written and the feed read within the cap.
- `partial: <reason>`: pages left unread, feed stopped early, or filters unavailable.
- `failed: <reason>`: login wall, CAPTCHA, browser unavailable, or no report.

## Forbidden

- SMTP password, cookies, session tokens, browser data.
- Fabricated posts, jobs, permalinks, metrics.
- Anything implying the user replied or applied.
- Logs longer than 20 lines.
