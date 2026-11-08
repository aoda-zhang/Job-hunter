---
name: daily-report
description: Save or update the local Markdown report produced by browser-based job discovery.
---

# Daily Job Discovery Report

This skill belongs only to Phase 1. Read the current discovery results and `job-hunter.config.json`.

Write exactly one report per local calendar date:

`reports/daily/YYYY-MM-DD.md`

Create the directory when needed. If today's report already exists, merge new vacancies and deduplicate by canonical job URL. Preserve previously collected entries; do not create timestamped duplicates.

Include confirmed matches and uncertain records marked for review. Exclude confirmed non-matches from the main report, but state their count in the summary.

For each vacancy include title, company, location/work mode when known, posting date and discovery date, JD language, matched technical keywords, the three filter results with evidence, source, direct URL, concise JD summary and original JD text or a clearly marked excerpt.

Group by company for readability only. Do not add company profiles, business-model analysis, culture commentary, interview questions or “Why join?” answers. Do not introduce extra filters or ranking. Mark missing facts as unknown rather than guessing.
