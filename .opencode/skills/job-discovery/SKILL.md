---
name: job-discovery
description: Search LinkedIn vacancies with the local OpenCode browser, inspect real job descriptions, filter only by job title, JD language, technical keywords and configured work modes, and save a daily Markdown report.
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
- `workModes`: accepted workplace types (`Remote`, `Hybrid`, `On-site`). Optional.
- `employmentTypes`: accepted employment types (`Full-time`, `Part-time`, `Contract`, `Temporary`, `Internship`, `Volunteer`). Optional.
- `lookbackHours`: posting window that defines the search scope.
- `sources`: configured source list; currently LinkedIn.
- `sortBy`: how to order matched rows inside each city — currently `companySize`; omit for discovery order.
- `sortDirection`: `asc` (default) or `desc`.
- `jobTitles.include`: target job-title variants.
- `jdLanguages.include`: accepted JD languages.
- `technicalKeywords.include` and `technicalKeywords.matchMode`: technology terms and matching mode.

Do not expect or add a `search` wrapper. Do not create another config file or ask the user to duplicate these values elsewhere.

Only job title, actual JD language, technical keywords and the configured work modes are matching filters. Country, location and posting date are search scope, not candidate-fit criteria.

## 2. Search LinkedIn using the available browser

First inspect which browser-control tools are actually available in this OpenCode session. Use the available configured browser integration; do not assume a tool name or claim browser access that is not present.

- Search LinkedIn Jobs using the configured countries, locations, title variants and posting window.
- Search title variants separately when needed so that one broad query does not hide relevant roles.
- Apply LinkedIn location and date-posted filters where the interface supports them. Treat these as search refinements, not additional match criteria.
- Read the workplace type from the result card or the vacancy page (LinkedIn renders it as `Remote`, `Hybrid` or `On-site`). Do not try to encode work mode in the search URL: the legacy `f_WT` parameter is dropped by the current AI search page, and clicking the `Remote` filter chip replaces the city scope with a country-wide remote search.
- Employment type is not shown on result cards, and the legacy `f_JT` parameter is dropped as well. Read it from the vacancy page after opening it.
- Open each potentially relevant vacancy and inspect the actual job description. Search-result snippets alone are insufficient to confirm a match.
- Inspect **every** distinct vacancy inside the configured posting window. There is no inspection cap: keep paginating each query until LinkedIn returns no further results within the window, and deduplicate collected URLs before opening pages so nothing is inspected twice.
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

### D. Work mode

Read the workplace type shown on the result card or vacancy page (`Remote`, `Hybrid`, `On-site`). Compare it with `workModes`:

- If `workModes` is absent, empty, or lists all three types, there is **no work-mode constraint** — this dimension never excludes anything.
- Otherwise only the listed types are accepted. A vacancy whose workplace type is not listed is a confirmed mismatch.
- If neither the card nor the page states a workplace type, mark this check `unknown`; never guess from the JD wording alone unless the JD states it explicitly.

### E. Employment type

Read the employment type from the vacancy page (`Full-time`, `Part-time`, `Contract`, `Temporary`, `Internship`, `Volunteer`). It is not shown on the result cards and the legacy `f_JT` URL parameter is dropped by the current AI search page, so this can only be decided after opening the vacancy.

- If `employmentTypes` is absent, empty, or lists every known type, there is **no employment-type constraint** — this dimension never excludes anything.
- Otherwise only the listed types are accepted. A vacancy whose employment type is not listed is a confirmed mismatch.
- If the page states no employment type, mark this check `unknown`; do not infer it from the title or the JD wording.

### Overall classification

- `matched`: all applicable checks are confirmed matches. A check that is disabled by configuration (see D) is not counted.
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

### Cross-day repeats

Repeating vacancies are expected, especially when `lookbackHours` exceeds 24. Before writing today's report, read the existing files in `reports/daily/` for the previous 7 local dates and build:

- the set of canonical URLs that appeared in a `matched` or `review` row;
- the set of company + normalised title + city triples from those rows.

Then:

- A vacancy whose URL already appeared is **still included** in today's report. Append `[已报 MM-DD]` to its note, using the earliest date found. Never drop the row, never move it to the excluded table, and never change its classification.
- A vacancy whose company + normalised title + city matches a previous row but whose URL differs is treated as a possible repost. Keep it as its own row and append `[疑似重发 MM-DD]`. Do not merge or suppress it.
- Never deduplicate against previously excluded vacancies: a vacancy rejected earlier must be re-evaluated if the configuration or the posting changed. Excluded rows therefore need no history.
- If no earlier reports exist, or a file is unreadable, skip that source silently.

This is annotation only. It must never reduce the number of inspected vacancies or hide a posting the current run actually found.

For each `matched` or `review` vacancy the reference format requires a single table row containing:
- company (as shown on LinkedIn) and job title as posted;
- work mode, or `未标注` when absent;
- posting date in relative Chinese form, and the discovery date via the report metadata;
- the configured technical keywords actually found;
- a short factual note (main stack, level, contract type, posting-vs-employer differences, field conflicts) with no fit judgement;
- the direct canonical job URL.

Do not restate the configured checks as prose, do not paste long JD text, and do not describe responsibilities in narrative form. Brief evidence belongs in the excluded table's reason column or in the note column.

Group matched entries by city. Within each city, order rows by company size using `sortBy` / `sortDirection`:

- `sortBy: "companySize"` sorts by the lower bound of the size range shown on the page (`11-50` → 11, `10001+` → 10001).
- `sortDirection` defaults to `asc`; use `desc` for largest first.
- Rows with the same size keep discovery order. If `sortBy` is missing or unknown, keep discovery order.
- After sorting, renumber the `#` column sequentially in the final display order and update any internal cross-references such as "与 #22 同一套 JD".

Never sort by a candidate-fit score. Do not perform company research or prepare interview answers in this phase.

## 6. Report completion accurately

At the end, state:
- report path;
- number of distinct LinkedIn vacancies inspected;
- confirmed matches;
- items requiring manual review;
- confirmed non-matches excluded;
- how many matched rows were flagged as cross-day repeats;
- any LinkedIn access or browser limitations, stated briefly and only when they actually occurred.

Inside the report itself, never add a limitations section on a normal run. Only a failed, interrupted or largely unevaluable run gets a short `异常说明` at the very end (see the format reference).

Only count pages actually opened and inspected. Clearly distinguish search results seen from job descriptions successfully reviewed. Never claim a search or inspection that did not happen.
