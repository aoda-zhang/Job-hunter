---
name: job-discovery
description: Use the configured browser workflow to find live vacancies locally, filter only by job title, JD language and technical keywords, and save a daily Markdown report.
---

# Job Discovery — Local Browser Workflow

This skill is the main entry point for Phase 1. Work locally in the current repository. The user expects OpenCode to operate the browser, inspect real job pages, and save a Markdown report. Do not ask the user to run a backend, database, CI pipeline, or source-adapter setup.

## 1. Read the single configuration

Read `job-hunter.config.json`. Use its search scope:
- `countries`
- `locations`
- `lookbackHours`
- `maxResultsPerSource`
- `sources`

Use exactly these three filters:
1. `jobTitles.include`
2. `jdLanguages.include`
3. `technicalKeywords.include` with `matchMode`

Country, location, date range and source are search scope only. They are not candidate-fit criteria.

## 2. Operate the browser

Use the browser-control tools available in this OpenCode environment (for example, its configured browser or Playwright MCP tools). Inspect the available browser tools before starting; do not assume a particular tool name.

- Search the configured job sites and public company career pages in the browser.
- Use the configured country, location, title variants and lookback window to form searches.
- Open promising result pages and inspect the actual job description, not just search-result snippets.
- Prefer the employer's own career page when the same vacancy is available there.
- Collect no more than `maxResultsPerSource` useful results from each configured source.
- If a page is inaccessible, record that limitation and continue with other sources.
- Do not bypass login controls, CAPTCHAs, paywalls, rate limits or other access restrictions. Do not scrape behind access controls. Never ask the user to share passwords or session tokens.
- Do not submit applications, send messages, create accounts or change account settings.

If no browser-control tool is available, explain that browser automation is not configured in this OpenCode environment. Do not pretend to have searched. You may provide browser search queries for the user to run manually.

## 3. Apply only the three filters

For each vacancy, inspect the full JD where possible.

### Job title
Compare the title with `jobTitles.include` using sensible semantic matching and common variants (for example, Frontend Developer and Frontend Engineer). Ignore seniority modifiers such as Senior, Mid-level or Junior when deciding whether the role family matches. Do not require exact string equality.

### JD language
Identify the language actually used in the JD. Do not infer it from the country, company or website interface. If the JD is missing, short, mixed or ambiguous, mark it `unknown` and keep the vacancy for review.

### Technical keywords
Search the JD text for configured keywords, case-insensitively. Recognize obvious spelling variants and aliases such as JS / JavaScript, TS / TypeScript, NodeJS / Node.js and ReactJS / React. Respect `matchMode`:
- `any`: at least one configured keyword is sufficient.
- `all`: every configured keyword must be found.

If the JD is truncated or inaccessible, do not interpret missing keywords as confirmed absence; mark the keyword check `unknown`.

### Overall result
- `matched`: all three dimensions match.
- `not_matched`: at least one dimension is a confirmed mismatch.
- `review`: no confirmed mismatch exists, but at least one dimension is unknown.

Keep every `matched` and `review` vacancy in the daily report. Do not rank jobs or calculate candidate-fit scores.

Do not filter by years of experience, seniority, salary, visa/work authorization, candidate language proficiency, industry, architecture, company size or any other candidate-profile criterion.

## 4. Save the local report

Create or update exactly one file for the current local date:

`reports/daily/YYYY-MM-DD.md`

Create the parent directory if it does not exist. If the file already exists, merge new results and deduplicate by canonical job URL; do not erase useful entries already collected that day.

For each included vacancy record:
- Job title and company.
- Country, location and work mode when available.
- Posting date (if shown) and date discovered.
- Detected JD language and evidence.
- Configured technical keywords found in the JD.
- The three filter outcomes and short reasons.
- Source name and direct job URL.
- A concise JD summary.
- The full JD text when it is reasonably short; otherwise save a useful excerpt and note that the source page contains the full description.

Group by company for readability only. Keep the report focused on helping the user decide which jobs to apply for. Do not research companies or prepare interview answers in this phase.

## 5. Final response

State the report path and a concise count of:
- vacancies inspected;
- confirmed matches;
- items requiring review;
- confirmed non-matches excluded from the main report.

Mention any sources that could not be accessed. Never claim a source was searched if it was not.
