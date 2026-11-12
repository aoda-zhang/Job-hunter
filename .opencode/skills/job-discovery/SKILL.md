---
name: job-discovery
description: Search the job platforms configured in sources with the local OpenCode browser, inspect real job descriptions, filter only by job title, JD language, technical keywords, configured work modes, employment types, optional seniority and direct-employer requirement, verify each posting is still open, and save a daily Markdown report.
---

# Job Discovery

This is the primary workflow of Job Hunter. Run it locally in this repository. OpenCode operates the browser tools already configured in the user's environment. This repository is an instruction harness, not an application: do not introduce a backend, database, CLI, CI pipeline, source adapters or extra configuration.

The platforms are not fixed in this skill. `sources` in the user's config decides where to search. Each platform's mechanics live in its own file under `references/`; section 2 is only the navigation layer that picks the right file and enforces the shared rules.

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
- `sources`: **required** list of job platforms to search, in order, for example `["LinkedIn"]` or `["LinkedIn", "Indeed", "Glassdoor"]`. See 2.1 for which reference each value uses. Never search a platform that is not listed, and never silently drop one that is.
- `preferredReportLanguage`: language of the daily report and the run-summary email body, e.g. `English`, `German`, `Chinese`. Defaults to `English` when absent or empty. It never changes the search query, matching, index keys or audit fields; the email subject stays ASCII.
- `reportRepo`: optional Git URL where the daily report is published after each run.
- `notifications.email`: optional SMTP settings for run-summary emails; disabled by default. When `enabled` is `true`, send exactly one summary through the `email-notify` skill after the index and audit are written.
- `sortBy`: how to order matched rows inside each city — currently `companySize`; omit for discovery order.
- `sortDirection`: `asc` (default) or `desc`.
- `jobSearchPrompt`: **required** natural-language search request. It is the only search query and is used verbatim on every configured source.
- `jobTitles.include`: target job-title variants. Used for matching and the card-level skip, never for building the query.
- `jdLanguages.include`: accepted JD languages.
- `jdLanguages.acceptGermanJdWithEnglishWorkingLanguage`: optional boolean. When `true`, a German-language JD still matches if it explicitly states that English is the working, team or company language.
- `technicalKeywords.include` and `technicalKeywords.matchMode`: technology terms and matching mode.

Do not expect or add a `search` wrapper. Do not create another config file or ask the user to duplicate these values elsewhere.

### Local job index and applied record

Read `reports/job-index.json` before searching. It is the local, Git-ignored memory of every vacancy already inspected, and its schema and rules live in `.opencode/skills/job-discovery/references/job-index-and-audit.md`.

- If a job's `appliedOn` is set, skip it before opening it and count it as applied-skipped; never list it in today's tables.
- Re-open jobs previously marked `matched` or `review` — they may be closed or changed. Annotate repeats with `[reported MM-DD]` from `firstReportedOn`.
- Re-evaluate jobs previously `excluded` or `expired`; do not annotate them as repeats.
- Flag likely duplicate postings (same company, normalized title and city with a different job ID) as `⚠️ possible duplicate`; if the other posting was applied to, use `⚠️ possibly applied MM-DD`. Never merge or delete them.
- If the index is missing, bootstrap it from the previous 7 daily reports; if that also fails, start empty.

If `jobSearchPrompt` is missing, empty or whitespace, stop and ask the user to write one natural-language search request. Do not build a query from `countries`, `locations` or `jobTitles.include`.

### Search scope resolution

Resolve the location scope before searching:

1. `countries` must contain at least one non-empty entry. If it is missing, empty or contains only blank strings, stop and ask the user to add a country. Do not guess one.
2. If `locations` contains at least one non-empty entry, the run's scope is limited to those country × city combinations; results clearly elsewhere are out of scope.
3. If `locations` is absent, empty or contains only blank strings, the scope is the **entire configured country**. For example, `countries: ["Germany"]` without `locations` means all of Germany — not a default city and not a silent narrowing.
4. Never silently narrow or widen the resolved scope. State the resolved scope in the final chat summary when it is nationwide, and say plainly that the whole country was in scope.

Only job title, actual JD language, technical keywords, configured work modes, employment types, optional seniority and the optional direct-employer requirement are matching filters. Country, location and posting date are search scope, not candidate-fit criteria. Posting validity is a gate, not a match dimension.

If the user states search criteria in the chat for one run, restate the effective criteria before searching and apply them to that run only. Do not silently persist chat-level criteria into the config; write a setting to `job-hunter.config.json` only when the user asks for a lasting change.

## 2. Search the configured sources

This section is the navigation layer. The mechanics of each job platform live in its own file directly under `.opencode/skills/job-discovery/references/`. Read the matching reference before searching and follow it; do not improvise a flow that a reference already defines, and do not copy one platform's UI steps onto another.

Check which browser-control tools exist. If none are available, stop and say so; never pretend to have searched.

Resolve the source list from `sources` before searching. If it is missing, empty or contains only blank strings, stop and ask the user which platforms to search — do not default to LinkedIn silently.

Record the run start time in ISO 8601 with the local UTC offset before the first search; the audit entry needs it as `runAt`.

Run the sources in the configured order and keep one shared result set. For each source:

1. Open that platform's reference and use its search entry point with the query described below, submitting it once.
2. Apply the config filters in that platform's own UI using that reference's mapping, then verify they are active.
3. Paginate until results fall outside `lookbackHours`. Deduplicate canonical URLs before opening pages and skip jobs marked `appliedOn` in the index; there is no inspection cap.
4. Skip a card without opening it only when its title clearly names a different function (for example sales, marketing, finance, HR, design or data analysis) and contains none of the configured role nouns or clear synonyms, or when the card is clearly outside the configured `countries`/`locations`. Everything ambiguous, truncated, localized or generic gets opened. This is the only allowed skip.
5. Open the remaining vacancies, prefer the canonical job URL, and keep one record per vacancy. Tag each record with its `source`.

### 2.1 Platform reference lookup

| Configured source | Reference |
|---|---|
| `LinkedIn` | `references/linkedin.md` |
| `Indeed` | `references/indeed.md` |
| `Glassdoor` (e.g. `glassdoor.de`) | `references/glassdoor.md` |
| a platform being added | `references/_template.md` |

Look up the platform name case-insensitively, ignoring a country domain (`Indeed` → `indeed.md`, `glassdoor.de` → `glassdoor.md`).

There is no fallback flow. A configured platform without its own reference is **not searched**: say which platform has no reference, point to `references/_template.md`, and continue with the sources that do. Never improvise a generic flow for an unknown site.

Each reference must cover the same points: search entry, query field, filter mapping, result extraction, pagination, access boundaries and known quirks. The filtering, reporting, index and safety rules stay in this skill.

### 2.2 The search query

`jobSearchPrompt` is the single query, used **verbatim** on every source. Do not rewrite, split, translate or append cities, and do not build a query from `countries`, `locations` or `jobTitles.include`. If it is missing or empty, stop and ask for it.

Platforms differ in what their query field accepts. Use the prompt as-is and let the platform parse it; do not pre-chew it into keywords. When a platform offers both a keyword box and a location box, put the prompt in the keyword box and set the location from `countries`/`locations`.

### 2.3 Failure isolation

Do not stop the whole run because one source fails. Record the failure in `limitations`, mark that source in `searchedBySource` as `failed` or `skipped`, continue with the next source, and say in the final summary which sources completed and which did not.

Never guess a platform's private API, scrape behind an authentication wall, or fabricate results for a source you could not search. A source that cannot be searched is reported as not searched, not as empty.

If any source requires login, shows a CAPTCHA or blocks the run, stop at that boundary and report it. Never ask for credentials, never bypass access controls, and never apply, message, save or follow anything.

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

While the page is open, also record the platform priority prompt when its reference defines one and the config enables it (LinkedIn: `linkedinPremium`). It is ordering metadata only: never a check, never an upgrade of `unknown`, and a failed vacancy stays excluded even with the prompt.

Also while the page is open, record two application-process fields for every inspected vacancy (matched, review or excluded). These are informational only — they never affect match/review/excluded classification:
- `easyApply`: `yes` when the page shows a one-click apply button on the platform (e.g. LinkedIn "Easy Apply", Indeed "Indeed Apply"), `no` when the apply path clearly leaves the platform or requires an external form, `unknown` when the button or its absence cannot be determined.
- `coverLetter`: `yes` when the page or application form explicitly says a cover letter is required, `no` when it explicitly says cover letter is optional or not needed, `unknown` when neither is stated.

Keep `matched` and `review` in the report; exclude `not_matched` from the main report. Never rank, score or label fit; the only priority signal is the platform's own prompt, quoted as shown. Do not filter on years, salary, visa, candidate language proficiency, industry, architecture or company size. Record only facts visible on the page; never infer a missing field.

## 4. Follow the daily report reference

Before writing or updating a daily report, read and follow the canonical format document:

`.opencode/skills/job-discovery/references/daily-report-format.md`

This reference defines the required report sections, vacancy layout, metadata, evidence presentation, run-summary counts and update behavior. Every daily report must follow it consistently. Do not invent a different layout for individual runs.

The reference fixes the structure; `preferredReportLanguage` fixes the language. Write every human-readable string — title, section headings, table headers, labels, relative times and annotation markers — in that language, and keep the structure, column order, date formats and URLs unchanged. Fall back to English when the field is absent, empty or names a language you cannot write, and say so in the final summary.

Index updates, deduplication and the run audit log follow `.opencode/skills/job-discovery/references/job-index-and-audit.md`.

## 5. Write the daily report

Create or update exactly one report for the current local date:

`reports/daily/YYYY-MM-DD.md`

Create the parent directory if needed. If today's report already exists, merge new findings rather than overwriting useful entries. Deduplicate by canonical job URL within and across sources; when no canonical URL is available, use a cautious combination of company, title and location and flag possible duplicates for review.

### Publish the daily file (optional)

If `reportRepo` is a non-empty Git URL, publish today's report after writing it:

1. Clone or pull `reportRepo` into a temporary directory.
2. Copy the report to `reports/daily/YYYY-MM-DD.md` there.
3. Commit `docs: add daily job results for YYYY-MM-DD` and push to the repository's default branch.
4. If authentication, pull or push fails, report it and keep the local report. Never force-push and never rewrite unrelated files.

Do not publish anything besides the day's report file.

### Update the local index and audit log

After the report is written:

1. Upsert every vacancy inspected today into `reports/job-index.json` by its source-qualified key: set `source`, `lastSeen` and `status`, set `firstSeen` on first sight, set `firstReportedOn` the first time it enters the matched or review table, set `easyApply` and `coverLetter` from the page inspection, and never clear `appliedOn`.
2. Append one JSON line for this run to `reports/runs/YYYY-MM-DD.jsonl` using the field list in `.opencode/skills/job-discovery/references/job-index-and-audit.md`. Use the recorded start as `runAt`, the current time as `finishedAt`, and their difference as `durationSeconds`.
3. Preserve unknown fields and every other entry. Never delete index entries automatically.

If `notifications.email.enabled` is `true`, load the `email-notify` skill and send one run summary after steps 1 and 2. Do not send when it is `false` or absent.

### Cross-day repeats

Before writing today's report, check each vacancy against `reports/job-index.json`, which covers all history. If the same job ID or canonical URL already entered a matched or review table, keep today's row and append `[reported MM-DD]` using `firstReportedOn`. Excluded and expired entries do not count. If the index is missing, fall back to the previous 7 daily reports. This is annotation only; it never reduces inspected vacancies.

For each `matched` or `review` vacancy the reference format requires a single table row containing:
- source platform, company as shown on that platform, and job title as posted;
- work mode, or `Not specified` when absent;
- posting date in relative Chinese form, and the discovery date via the report metadata;
- the configured technical keywords actually found;
- a short factual note (main stack, level, contract type, posting-vs-employer differences, field conflicts) with no fit judgement;
- the direct canonical job URL.

Do not restate the configured checks as prose, do not paste long JD text, and do not describe responsibilities in narrative form. Brief evidence belongs in the excluded table's reason column or in the note column.

Group matched entries by city. When the run is nationwide (no `locations`), the city comes from each vacancy page, so group by the cities actually found and follow the format reference for country-level or remote-only postings. Prompted matches form one leading group before the city groups (format reference) but still count in their city's share. Within each city, order rows by company size using `sortBy` / `sortDirection`:

- `sortBy: "companySize"` sorts by the lower bound of the size range shown on the page (`11-50` → 11, `10001+` → 10001).
- `sortDirection` defaults to `asc`; use `desc` for largest first.
- Rows with the same size keep discovery order. If `sortBy` is missing or unknown, keep discovery order.
- After sorting, renumber the `#` column sequentially in the final display order across the priority group and the city groups, and update any internal cross-references such as "same JD as #22".

Never sort by a candidate-fit score. Do not perform company research or prepare interview answers in this phase.

## 6. Report completion accurately

At the end, state:
- report path;
- the resolved search scope, explicitly noting when it was nationwide (for example `All Germany`) because `locations` was empty;
- the exact `jobSearchPrompt` used;
- number of distinct vacancies inspected, broken down by source;
- number of applied jobs skipped from the index;
- number of result cards skipped before opening (off-family title or out of scope);
- number of expired or closed postings skipped by the validity check;
- confirmed matches, and how many of them carried the platform priority prompt;
- items requiring manual review;
- confirmed non-matches excluded;
- how many matched rows were flagged as cross-day repeats;
- how many likely duplicates were flagged (different job ID, same role);
- coverage per source: the result count when the page shows one, how many result pages were opened, and why pagination stopped, all taken from the run audit entry;
- whether the summary email was sent, skipped because notifications are disabled, or failed;
- any source access or browser limitations, naming the affected source, stated briefly and only when they actually occurred;

Inside the report itself, never add a limitations section on a normal run. Only a failed, interrupted or largely unevaluable run gets a short `Exception note` at the very end (see the format reference).

Only count pages actually opened and inspected. Clearly distinguish search results seen from job descriptions successfully reviewed. Never claim a search or inspection that did not happen.
