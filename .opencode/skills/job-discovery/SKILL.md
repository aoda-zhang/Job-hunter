---
name: job-discovery
description: Search LinkedIn vacancies with the local OpenCode browser, inspect real job descriptions, filter only by job title, JD language, technical keywords, configured work modes, employment types, optional seniority and direct-employer requirement, verify each posting is still open, and save a daily Markdown report.
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

- `countries`: country-level scope boundary for the run. Required. Used to validate results and describe the scope; it does not build the search query.
- `locations`: optional city-level refinement of `countries`; when absent or empty the whole country is in scope.
- `workModes`: accepted workplace types (`Remote`, `Hybrid`, `On-site`). Optional.
- `employmentTypes`: accepted employment types (`Full-time`, `Part-time`, `Contract`, `Temporary`, `Internship`, `Volunteer`). Optional.
- `seniority.include`: accepted levels (`Junior`, `Mid-level`, `Senior`, `Lead`). Optional; disabled when absent, empty or listing every level.
- `excludeRecruiters`: when `true`, exclude postings from staffing and recruiting agencies that hire for a third-party client. Optional; absent or `false` disables it.
- `lookbackHours`: posting window that defines the search scope.
- `sources`: configured source list; currently LinkedIn.
- `reportRepo`: optional Git URL where the daily report is published after each run.
- `sortBy`: how to order matched rows inside each city — currently `companySize`; omit for discovery order.
- `sortDirection`: `asc` (default) or `desc`.
- `jobSearchPrompt`: **required** natural-language search request for LinkedIn's AI job search. It is the only search query and is used verbatim.
- `jobTitles.include`: target job-title variants. Used for matching and the card-level skip, never for building the query.
- `jdLanguages.include`: accepted JD languages.
- `jdLanguages.acceptGermanJdWithEnglishWorkingLanguage`: optional boolean. When `true`, a German-language JD still matches if it explicitly states that English is the working, team or company language.
- `technicalKeywords.include` and `technicalKeywords.matchMode`: technology terms and matching mode.

Do not expect or add a `search` wrapper. Do not create another config file or ask the user to duplicate these values elsewhere.

If `jobSearchPrompt` is missing, empty or whitespace, stop and ask the user to write one natural-language search request. Do not build a query from `countries`, `locations` or `jobTitles.include`.

### Search scope resolution

Resolve the location scope before searching:

1. `countries` must contain at least one non-empty entry. If it is missing, empty or contains only blank strings, stop and ask the user to add a country. Do not guess one.
2. If `locations` contains at least one non-empty entry, the run's scope is limited to those country × city combinations; results clearly elsewhere are out of scope.
3. If `locations` is absent, empty or contains only blank strings, the scope is the **entire configured country**. For example, `countries: ["Germany"]` without `locations` means all of Germany — not a default city and not a silent narrowing.
4. Never silently narrow or widen the resolved scope. State the resolved scope in the final chat summary when it is nationwide, and say plainly that the whole country was in scope.

Only job title, actual JD language, technical keywords, configured work modes, employment types, optional seniority and the optional direct-employer requirement are matching filters. Country, location and posting date are search scope, not candidate-fit criteria. Posting validity is a gate, not a match dimension.

If the user states search criteria in the chat for one run, restate the effective criteria before searching and apply them to that run only. Do not silently persist chat-level criteria into the config; write a setting to `job-hunter.config.json` only when the user asks for a lasting change.

## 2. Search LinkedIn

Check which browser-control tools exist. If none are available, stop and say so; never pretend to have searched.

1. Open LinkedIn Jobs' AI search, enter `jobSearchPrompt` **verbatim** and submit it once. Do not rewrite, split, translate or append cities. If the prompt is missing or empty, stop and ask for it.
2. Apply the config filters in the UI using the rules below, then verify they are active.
3. Paginate until results fall outside `lookbackHours`. Deduplicate canonical URLs before opening pages; there is no inspection cap.
4. Skip a card without opening it only when its title clearly names a different function (for example sales, marketing, finance, HR, design or data analysis) and contains none of the configured role nouns or clear synonyms, or when the card is clearly outside the configured `countries`/`locations`. Everything ambiguous, truncated, localized or generic gets opened. This is the only allowed skip.
5. Open the remaining vacancies, prefer the canonical job URL, and keep one record per vacancy.

### Apply config filters in the UI

Text inside `jobSearchPrompt` is not a filter: LinkedIn does not reliably enforce "24 hours", "full-time" or similar wording written in the prompt. After submitting the prompt and before paginating, set the filters in LinkedIn's filter bar:

1. **Date posted** — map `lookbackHours`: ≤24 → `Past 24 hours`; ≤168 → `Past week`; ≤720 → `Past month`; larger → no date filter. Pick the closest bucket that fully covers the window, never a narrower one. Still check each posting's date against `lookbackHours` when opening it.
2. **Employment type** — when `employmentTypes` is a real subset, open the Employment type filter and check exactly those labels (`Full-time`, `Part-time`, `Contract`, `Temporary`, `Internship`, `Volunteer`).
3. **Work mode** — when `workModes` is a real subset of `Remote` / `Hybrid` / `On-site`, select the matching filter.
4. **Seniority** — only when `seniority.include` is configured and the UI labels map unambiguously; otherwise skip the UI filter and judge on the page.
5. **Location** — set the configured country, and cities only when `locations` is non-empty, if a location filter is available.

Do not add filters that are not in the config, such as salary, company, Easy Apply or applicant count. Use the visible filter controls; URL parameters like `f_TPR` and `f_JT` may be dropped by the AI search page.

Verify the filters show as checked or active before reading results. If the page resets them after a re-submit, apply them again. If a filter cannot be applied, say so and fall back to reading that field on each posting; never assume the prompt filtered it.

If LinkedIn requires login, shows a CAPTCHA or blocks the run, stop at that boundary and report it. Never ask for credentials, never bypass access controls, and never apply, message, save or follow anything.

## 3. Inspect and classify

Open the page and confirm the posting is still open. Then evaluate the checks below **in order and stop at the first confirmed mismatch**; do not keep reading a vacancy that already fails. If a check is unclear after a quick look, mark it `unknown` and move on — do not re-open the page or browse elsewhere to resolve it.

0. **Posting validity** — 404, redirect away from the job, or `No longer accepting applications` / `This job is no longer available` / `Bewerbung nicht mehr möglich` → skip, count as expired or closed, do not classify.
1. **Job title** — same role family as `jobTitles.include`. The page title wins over the card title.
2. **Poster type** — active only when `excludeRecruiters` is `true`. Judge from the posting page only: a known staffing firm, `our client` / `im Auftrag unseres Kunden`, or an agency apply portal. A consultancy hiring for its own projects is an employer. Do not open the company page just for this; unclear → `unknown`.
3. **JD language** — in `jdLanguages.include`. If `jdLanguages.acceptGermanJdWithEnglishWorkingLanguage` is `true` and a German JD explicitly names English as the working, team or company language → match; record that phrase. Mixed, short or truncated → `unknown`.
4. **Technical keywords** — follow `technicalKeywords.matchMode` (`any` / `all`) and accept common aliases (JS/JavaScript, TS/TypeScript, NodeJS/Node.js, ReactJS/React); with `any`, stop scanning once one keyword is found.
5. **Work mode** — only when `workModes` is a real subset of `Remote` / `Hybrid` / `On-site`. Missing → `unknown`.
6. **Employment type** — only when `employmentTypes` is a real subset. Missing → `unknown`.
7. **Seniority** — only when `seniority.include` is a real subset of `Junior` / `Mid-level` / `Senior` / `Lead`. Use the title or explicit level wording, never a bare "5+ years". Missing → `unknown`.

Disabled checks are skipped. Confirmed mismatch → `not_matched`, stop. No mismatch but any `unknown` → `review`. Otherwise `matched`.

Keep `matched` and `review` in the report; exclude `not_matched` from the main report. Never rank, score or label fit. Do not filter on years, salary, visa, candidate language proficiency, industry, architecture or company size. Record only facts visible on the page; never infer a missing field.

## 4. Follow the daily report reference

Before writing or updating a daily report, read and follow the canonical format document:

`.opencode/skills/job-discovery/references/daily-report-format.md`

This reference defines the required report sections, vacancy layout, metadata, evidence presentation, run-summary counts and update behavior. Every daily report must follow it consistently. Do not invent a different layout for individual runs.

## 5. Write the daily report

Create or update exactly one report for the current local date:

`reports/daily/YYYY-MM-DD.md`

Create the parent directory if needed. If today's report already exists, merge new findings rather than overwriting useful entries. Deduplicate by canonical LinkedIn job URL; when no canonical URL is available, use a cautious combination of company, title and location and flag possible duplicates for review.

### Publish the daily file (optional)

If `reportRepo` is a non-empty Git URL, publish today's report after writing it:

1. Clone or pull `reportRepo` into a temporary directory.
2. Copy the report to `reports/daily/YYYY-MM-DD.md` there.
3. Commit `docs: add daily job results for YYYY-MM-DD` and push to the repository's default branch.
4. If authentication, pull or push fails, report it and keep the local report. Never force-push and never rewrite unrelated files.

Do not publish anything besides the day's report file.

### Cross-day repeats

Before writing today's report, read the previous 7 daily reports and collect the canonical URLs that appeared in `matched` or `review` rows. If a URL already appeared, keep the row and append `[已报 MM-DD]` using the earliest date. Excluded rows are not used for this check. This is annotation only; it never reduces inspected vacancies.

For each `matched` or `review` vacancy the reference format requires a single table row containing:
- company (as shown on LinkedIn) and job title as posted;
- work mode, or `未标注` when absent;
- posting date in relative Chinese form, and the discovery date via the report metadata;
- the configured technical keywords actually found;
- a short factual note (main stack, level, contract type, posting-vs-employer differences, field conflicts) with no fit judgement;
- the direct canonical job URL.

Do not restate the configured checks as prose, do not paste long JD text, and do not describe responsibilities in narrative form. Brief evidence belongs in the excluded table's reason column or in the note column.

Group matched entries by city. When the run is nationwide (no `locations`), the city comes from each vacancy page, so group by the cities actually found and follow the format reference for country-level or remote-only postings. Within each city, order rows by company size using `sortBy` / `sortDirection`:

- `sortBy: "companySize"` sorts by the lower bound of the size range shown on the page (`11-50` → 11, `10001+` → 10001).
- `sortDirection` defaults to `asc`; use `desc` for largest first.
- Rows with the same size keep discovery order. If `sortBy` is missing or unknown, keep discovery order.
- After sorting, renumber the `#` column sequentially in the final display order and update any internal cross-references such as "与 #22 同一套 JD".

Never sort by a candidate-fit score. Do not perform company research or prepare interview answers in this phase.

## 6. Report completion accurately

At the end, state:
- report path;
- the resolved search scope, explicitly noting when it was nationwide (for example `全德国`) because `locations` was empty;
- the exact `jobSearchPrompt` used;
- number of distinct LinkedIn vacancies inspected;
- number of result cards skipped before opening (off-family title or out of scope);
- number of expired or closed postings skipped by the validity check;
- confirmed matches;
- items requiring manual review;
- confirmed non-matches excluded;
- how many matched rows were flagged as cross-day repeats;
- any LinkedIn access or browser limitations, stated briefly and only when they actually occurred.

Inside the report itself, never add a limitations section on a normal run. Only a failed, interrupted or largely unevaluable run gets a short `异常说明` at the very end (see the format reference).

Only count pages actually opened and inspected. Clearly distinguish search results seen from job descriptions successfully reviewed. Never claim a search or inspection that did not happen.
