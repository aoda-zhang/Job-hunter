---
name: daily-report
description: Produce a concise dated Markdown report of job vacancies found during the application-search stage.
---

# Daily Job Discovery Report

This skill belongs exclusively to **Phase 1 — Job Discovery / Application Search**. Read the final discovery results and the root `job-hunter.config.json`.

Do not run company research or interview preparation from this skill. Do not read company-research or interview-preparation records to enrich the daily report.

## File rule

Create or update exactly one Markdown file for each report-generation calendar date:

`reports/daily/YYYY-MM-DD.md`

Use the machine's local calendar date for the filename. If the report is run more than once on the same date, update the existing date file and merge/deduplicate the day's results by canonical job URL. Do not create timestamped duplicates for the same day.

## Included vacancies

Include:
- confirmed matches; and
- uncertain/incomplete records marked for manual review.

Do not include confirmed non-matches in the main report. Keep them in the database/audit trail. Do not apply additional candidate-fit, seniority, salary, visa, architecture or experience filters.

## Required content

Start with a concise summary showing the report date, total vacancies, confirmed matches and items requiring review.

Group vacancies by company for readability only. Company grouping is not company research. Do not add company profiles, business-model analysis, market analysis or company-culture commentary.

For every vacancy, include:
- Job title.
- Company name.
- Country, city/location and work mode when known.
- Posting date and discovery date, clearly distinguished.
- JD language: detected value, or Unknown / Review when it cannot be determined.
- Technical keywords: configured keywords found in the JD; do not imply that an absent keyword is a rejection unless the configured matching rule says so.
- Filter outcome and concise evidence for the three dimensions: job title, JD language and technical keywords.
- Source and canonical job URL.
- A concise JD summary, plus the original JD in a collapsible section when available.

Do not include:
- Company deep research or company overview.
- “Why do you want to join our company?” answers.
- Interview questions, interview scripts or company-specific preparation.
- Recommendations to apply or reject based on criteria outside the three configured filters.

## Quality checks

- Preserve all included results; do not silently omit review items.
- Deduplicate repeated postings by canonical URL.
- Mark unavailable or ambiguous fields explicitly; never guess.
- Distinguish posting date from report date.
- Keep the report focused on helping the user review vacancies and decide which applications to submit.

The report is a discovery aid only. Never submit applications or contact employers.
