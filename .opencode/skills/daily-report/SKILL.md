---
name: daily-report
description: Produce one dated Markdown report for the final job-search results, with company business profiles and tailored why-join interview answers.
---

# Daily Job Search Report

Read the final results for the current search run, the root `job-hunter.config.json`, and the company-research output.

## File rule

Create or update exactly one Markdown file for each report-generation calendar date:

`reports/daily/YYYY-MM-DD.md`

Use the machine's local calendar date for the filename. If the report is run more than once on the same date, update the existing date file and merge/deduplicate the day's results by canonical job URL. Do not create timestamped duplicates for the same day.

## Included vacancies

Include:
- confirmed matches; and
- uncertain/incomplete records marked for manual review.

Do not include confirmed non-matches in the main report. Keep them in the database/audit trail. Do not apply any additional candidate-fit, seniority, salary, visa, architecture or experience filters.

Group vacancies by company. If one company has multiple vacancies, show its company profile once and list all its roles underneath.

## Required content

For each company:
- Company name and verified website.
- **Main business:** what it sells/provides, its core products/services, customer groups and business model when verifiable.
- Brief relevance to the vacancy's product, team or business area.
- Source URLs and publication/access dates for material company claims.

For every materially different vacancy:
- Job title, location, work mode if known, posting date if known, source and canonical job URL.
- JD language and technical keywords matched.
- Filter outcome and concise evidence; label unknown dimensions clearly.
- **Interview answer — “Why do you want to join our company?”** Write a natural first-person spoken answer grounded in verified company facts, the specific role and candidate experience found in supplied candidate materials. Normally target 80–130 words in the known interview language. Do not invent motivations, achievements or company facts. If context is missing, label the answer as a draft and state what needs personalization.

## Quality checks

- Preserve all included results; do not silently omit review items.
- Deduplicate repeated postings by canonical URL.
- Verify each company fact against cited sources.
- Tailor the answer to the company and role; reject generic boilerplate.
- Distinguish posting date from report date.
- If research is incomplete, state the gap rather than guessing.

The report is a preparation aid only. Never submit applications or contact employers.
