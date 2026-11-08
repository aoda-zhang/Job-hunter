---
name: job-analysis
description: Apply the three configured vacancy filters to a vacancy found during local browser-based job discovery.
---

# Job Filtering

This skill is used by `job-discovery` while reviewing vacancies in the browser. Read `job-hunter.config.json` and evaluate only:

1. Job title against `search.jobTitles.include`.
2. Actual JD language against `search.jdLanguages.include`.
3. Technical keywords in the JD against `search.technicalKeywords.include`, using `matchMode` (`any` or `all`).

Use semantic title matching and common title variants. Ignore seniority wording when determining the role family. Detect language from the JD, not the country or website. Match keywords case-insensitively and recognize clear aliases such as JS / JavaScript and TS / TypeScript.

For every dimension return `match`, `no_match` or `unknown`, with a short evidence-based reason.

Overall:
- `matched`: all three dimensions match.
- `not_matched`: at least one dimension is a confirmed mismatch.
- `review`: no confirmed mismatch exists, but at least one dimension is unknown.

Short, missing, mixed, inaccessible or truncated JD content must produce `unknown`, not a guessed mismatch. Keep unknown jobs in the report for manual review.

Never calculate candidate-fit scores. Never filter by years of experience, seniority, salary, visa/work authorization, candidate language proficiency, industry, architecture or any other candidate-profile criterion. Do not apply or contact employers.
