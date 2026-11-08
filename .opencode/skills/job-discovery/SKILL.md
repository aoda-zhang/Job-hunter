---
name: job-discovery
description: Search LinkedIn vacancies with the local OpenCode browser, inspect real job descriptions, filter only by job title, JD language and technical keywords, and save a daily Markdown report.
---

# LinkedIn Job Discovery

This is the primary workflow of Job Hunter. Run it locally in this repository. OpenCode operates the browser tools already configured in the user's environment. This repository is an instruction harness, not an application: do not introduce a backend, database, CLI, CI pipeline, source adapters or extra configuration.

## 1. Read the user's local configuration

Read the root file `job-hunter.config.json`. This is a personal, Git-ignored file and is the single source of runtime configuration.

The repository provides `job-hunter.config.example.json` only as a template. Never treat the example as the user's active preferences when their personal config is missing.

If `job-hunter.config.json` does not exist:
1. Tell the user to copy `job-hunter.config.example.json` to `job-hunter.config.json`.
2. Ask them to customize it for their own search.
3. Stop the discovery run until the personal config exists. Do not silently use the example.

All settings are top-level fields:

- `countries`, `locations`: LinkedIn search scope.
- `lookbackHours`: preferred posting window.
- `maxResultsPerSource`: maximum number of LinkedIn vacancies to inspect.
- `sources`: configured source list; currently LinkedIn.
- `jobTitles.include`: target job-title variants.
- `jdLanguages.include`: accepted JD languages.
- `technicalKeywords.include` and `technicalKeywords.matchMode`: technology terms and matching mode.

Do not expect or add a `search` wrapper. Do not create another config file or ask the user to duplicate these values elsewhere.

Only job title, actual JD language and technical keywords are matching filters. Country, location and posting date are search scope, not candidate-fit criteria.

## 2. Search LinkedIn using the available browser

First inspect which browser-control tools are actually available in this OpenCode session. Use the available configured browser integration; do not assume a tool name or claim browser access that is not present.

- Search LinkedIn Jobs using the configured countries, locations, title variants and posting window.
- Search title variants separately when needed so that one broad query does not hide relevant roles.
- Apply LinkedIn location and date-posted filters where the interface supports them. Treat these as search refinements, not additional match criteria.
- Open each potentially relevant vacancy and inspect the actual job description. Search-result snippets alone are insufficient to confirm a match.
- Inspect no more than `maxResultsPerSource` distinct LinkedIn vacancies in one run.
- Record the direct LinkedIn job URL and prefer its canonical job page.
- If the same vacancy appears more than once, keep one record and note alternate URLs only when useful.
- If LinkedIn requires login and the current browser session is not authenticated, stop at that access boundary and report it. Never ask the user for passwords, cookies or session tokens.
- Do not bypass login controls, CAPTCHAs, rate limits or other access restrictions.
- Do not apply for jobs, message recruiters, save jobs, follow companies, create accounts or change account settings.

If no browser-control tool is available, say clearly that browser automation is not configured in this OpenCode environment. Do not pretend to have searched LinkedIn. You may provide the user with search queries to run manually, but do not create a report containing fabricated results.

## 3. Inspect and classify each vacancy

Inspect the full JD whenever accessible. Evaluate the following dimensions independently and record concise evidence for each.

### A. Job title

Compare the vacancy title with `jobTitles.include` using semantic role-family matching and common wording variants (for example, Frontend Developer and Frontend Engineer).

Seniority wording such as Senior, Mid-level or Junior is not an additional rejection rule. Do not require exact title equality. A clearly different role family is a mismatch.

### B. JD language

Identify the language actually used in the job description. Do not infer it from the country, company headquarters or LinkedIn interface language.

Compare it with `jdLanguages.include`. If the JD is missing, too short, mixed, truncated or ambiguous, mark the language check `unknown`; do not guess.

### C. Technical keywords

Search the JD text case-insensitively for the configured terms. Recognize clear aliases and spelling variants, for example:
- JS / JavaScript
- TS / TypeScript
- NodeJS / Node.js
- ReactJS / React

Follow `technicalKeywords.matchMode` exactly:
- `any`: at least one configured keyword must be found.
- `all`: every configured keyword must be found.

Do not add unconfigured technologies as mandatory filters. If the JD is inaccessible or truncated such that absence cannot be established, mark this check `unknown`, not mismatch.

### Overall classification

- `matched`: all three checks are confirmed matches.
- `review`: no check is a confirmed mismatch, but at least one check is unknown.
- `not_matched`: at least one check is a confirmed mismatch.

Keep all `matched` and `review` vacancies in the report. Exclude confirmed `not_matched` vacancies from the main report, but include their count in the run summary.

Never rank vacancies, calculate weighted scores or produce Strong/Good Match labels.

Do not filter by candidate years of experience, seniority, salary, visa or work authorization, candidate language proficiency, industry, architecture, company size or any other candidate-profile criterion.

## 4. Follow the daily report reference

Before writing or updating a daily report, read and follow the canonical format document:

`.opencode/skills/job-discovery/references/daily-report-format.md`

This reference defines the required report sections, vacancy layout, metadata, evidence presentation, run-summary counts and update behavior. Every daily report must follow it consistently. Do not invent a different layout for individual runs.

## 5. Write the daily report

Create or update exactly one report for the current local date:

`reports/daily/YYYY-MM-DD.md`

Create the parent directory if needed. If today's report already exists, merge new findings rather than overwriting useful entries. Deduplicate by canonical LinkedIn job URL; when no canonical URL is available, use a cautious combination of company, title and location and flag possible duplicates for review.

For each `matched` or `review` vacancy include:
- Job title and company.
- Country, city/location and work mode, if shown.
- Posting date, if shown, and date discovered.
- JD language and brief evidence.
- Configured technical keywords found.
- Separate outcomes and short evidence for all three checks.
- Overall status: `matched` or `review`.
- Source: LinkedIn.
- Direct job URL.
- Concise summary of responsibilities and required technologies.
- Full JD text when reasonably short; otherwise a useful excerpt and a note that the original page contains the full JD.

Group entries by company for readability only. Do not sort them by a candidate-fit score. Do not perform company research or prepare interview answers in this phase.

## 6. Report completion accurately

At the end, state:
- report path;
- number of distinct LinkedIn vacancies inspected;
- confirmed matches;
- items requiring manual review;
- confirmed non-matches excluded;
- any LinkedIn access or browser limitations.

Only count pages actually opened and inspected. Clearly distinguish search results seen from job descriptions successfully reviewed. Never claim a search or inspection that did not happen.
