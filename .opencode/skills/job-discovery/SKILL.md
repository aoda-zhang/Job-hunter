---
name: job-discovery
description: Search the platforms in sources with the local browser, inspect real JDs, filter by title, JD language, technical keywords, work mode, employment type and optional seniority, separate confirmed third-party postings unless configured otherwise, record explicit company business, verify the posting is open, and write the daily report.
---

# Job Discovery

Run locally in this repository. Use the configured browser tools. Do not add a backend, database, CLI, CI or source adapters.

## 1. Read config

Read `job-hunter.config.json`. It is the single runtime config and is Git-ignored. Never use `job-hunter.config.example.json` as the user's preferences.

If the personal config is missing, tell the user to copy the example, customize it, and stop.

Fields:

- `countries` — required scope boundary. It does not build the query.
- `locations` — optional city refinement. Empty = whole country.
- `workModes`, `employmentTypes`, `seniority.include` — optional filters.
- `thirdPartyPostings` — how confirmed third-party postings are handled: `separate` (default) keeps them in a dedicated `代招岗位` section, `include` lists them with normal matches, `exclude` drops them.
- `lookbackHours` — posting window.
- `sources` — required platform list, in order.
- `jobSearchPrompt` — required query, used verbatim.
- `jobTitles.include` — title matching.
- `jdLanguages.include`, `.acceptGermanJdWithEnglishWorkingLanguage` — JD language.
- `technicalKeywords.include`, `.matchMode` — stack matching.
- `preferredReportLanguage`, `reportRepo`, `notifications.email`, `sortBy`, `sortDirection`, `isNeededCover`.

Do not add a `search` wrapper or a second config file.

## 2. Resolve index and scope

Read `reports/job-index.json` with the rules in `.opencode/skills/job-discovery/references/job-index-and-audit.md`.

- Skip jobs with `appliedOn` and count them as applied-skipped.
- Re-open `matched` and `review` jobs; annotate repeats with `[reported MM-DD]` from `firstReportedOn`.
- Re-evaluate `excluded` and `expired` jobs without repeat annotation.
- Flag likely duplicates (same company, normalized title, city, different ID) as `⚠️ possible duplicate`; add `possibly applied MM-DD` when the other job was applied to.
- If the index is missing, rebuild from the previous 7 daily reports; otherwise start empty.

Resolve scope:

1. Require one non-empty `countries` entry; otherwise stop and ask.
2. `locations` non-empty = those country × city combinations only.
3. `locations` empty = the entire configured country. Do not narrow silently.
4. State the resolved scope in the final summary.

Only title, JD language, technical keywords, work modes, employment types and seniority are matching filters. Poster type is a display split for confirmed third-party postings (or an exclusion only when `thirdPartyPostings` is `exclude`). Country, city and posting date are scope. Validity is a gate.

If the user gives one-run criteria in chat, restate them and apply them to that run only.

## 3. Search sources

Read the platform reference before searching. Use this map:

| Source | Reference |
|---|---|
| `LinkedIn` | `references/linkedin.md` |
| `Indeed` | `references/indeed.md` |
| `Glassdoor` (e.g. `glassdoor.de`) | `references/glassdoor.md` |
| new platform | `references/_template.md` |

Match case-insensitively and ignore a country domain. Never improvise a flow for a platform without a reference; skip it, name it and continue.

If no browser tool exists, stop and say so. If `sources` is empty, ask which platforms to use.

Record the start time in ISO 8601 with the local offset as `runAt`.

For each source in order:

1. Open the reference and submit `jobSearchPrompt` once.
2. Apply the config filters in the platform UI and verify they are active.
3. Paginate until results fall outside `lookbackHours`. Deduplicate canonical URLs and skip `appliedOn` jobs. There is no inspection cap.
4. Skip a card without opening it only when its title clearly names another function and contains no configured role noun, or when it is clearly outside `countries`/`locations`. Open everything ambiguous.
5. Open the rest, prefer the canonical URL, and keep one record per vacancy tagged with `source`.

Use `jobSearchPrompt` verbatim on every platform. Do not rewrite, split, translate or append cities. Put it in the keyword field; set location from `countries`/`locations`.

Do not stop the whole run for one source failure. Record it in `limitations` and `searchedBySource`, continue, and report it. Never guess a private API, bypass login/CAPTCHA, or fabricate results. Discovery never applies, messages, saves or follows anything: Easy Apply is left to the user, and external applications happen only later in `job-apply`.

## 4. Inspect and classify

Open the posting and confirm it is still open. Evaluate in order and stop at the first confirmed mismatch.

0. **Validity** — 404, redirect, or "no longer accepting applications" → skip as expired/closed.
1. **Job title** — same role family as `jobTitles.include`. Page title wins over card title.
2. **Poster type** — classify from the posting as `direct`, `third_party` or `unknown`. `third_party` means a staffing firm, headhunter, agency portal, "our client", "on behalf of", or the local-language equivalent (e.g. `im Auftrag`, `für unseren Kunden`, `Arbeitnehmerüberlassung`). A consultancy hiring for its own projects is `direct`. Unclear → `unknown`. With `thirdPartyPostings: exclude`, a confirmed `third_party` is `not_matched` and stops here; with `separate` or `include`, continue and let the remaining checks decide.
3. **JD language** — in `jdLanguages.include`. A German JD matches when `acceptGermanJdWithEnglishWorkingLanguage` is `true` and the JD names English as the working language. Mixed, short or truncated → `unknown`.
4. **Technical keywords** — follow `matchMode`; accept JS/JavaScript, TS/TypeScript, NodeJS/Node.js, ReactJS/React. With `any`, stop at the first hit.
5. **Work mode** — only when `workModes` is a real subset. Missing → `unknown`.
6. **Employment type** — only when `employmentTypes` is a real subset. Missing → `unknown`.
7. **Seniority** — only when `seniority.include` is a real subset. Use title or explicit level, never bare years. Missing → `unknown`.
8. **Company business** — informational, never a filter. Record one short phrase only when the JD explicitly states the company's product, market or industry; otherwise `Not stated`. Never infer it from the company name, domain, another page or general knowledge.

Disabled checks are skipped. Confirmed mismatch → `not_matched`, stop. Any `unknown` with no mismatch → `review`. Otherwise `matched`.

Record `easyApply` (`yes`/`no`/`unknown`), `applyType` (`easy_apply` when the button applies inside the platform, `external` when it clearly redirects to an employer/ATS page, `unknown` otherwise) and `coverLetter` (`yes`/`no`/`unknown`) for every inspected vacancy. These are informational and never affect classification. Do not click Apply during discovery; classify from the visible button and page only.

Record `posterType` for every inspected vacancy that reaches the report. Record `business` only from an explicit JD statement. For a `third_party` posting, `business` describes the client employer's business when the JD states it; the client employer goes in Notes.

Record the platform priority prompt when the reference defines one and the config enables it (LinkedIn: `linkedinPremium`). It only orders rows. Recorded `easyApply` is also ordering metadata only and never a filter.

Keep `matched` and `review`; exclude `not_matched` from the main report. Never score fit. Do not filter on years, salary, visa, language proficiency, industry, architecture or company size. Record only page facts.

Draft a cover letter only when `isNeededCover` is `true` and `coverLetter` is `yes`, for a `matched` or `review` vacancy. Use `cover-letter-template.md` exactly: keep structure, sections, wording and order; fill only its placeholders from the page; leave unfillable placeholders unchanged and tell the user. Never fabricate. Save to `reports/cover-letters/<company-slug>/<jobId>.md` (`<company-slug>`: lowercase, spaces/punctuation → `-`). Do not submit. If the template is missing, stop that step and tell the user to copy `cover-letter-template-example.md`.

## 5. Write the report

Follow `.opencode/skills/job-discovery/references/daily-report-format.md` for structure, sections, columns, metadata and summaries. Write human-readable strings in `preferredReportLanguage`; keep structure, order, dates and URLs unchanged.

Write `reports/daily/YYYY-MM-DD.md`. Merge with an existing report. Preserve any `代招岗位` and `Feed-sourced jobs` sections and their counts. Deduplicate by canonical URL; without one, use company + title + location and flag possible duplicates.

When `thirdPartyPostings` is `separate`, put confirmed `third_party` postings that passed every other check in the dedicated `代招岗位` section, with the same columns, keyword evidence, ordering and checks as matched jobs. They count as matched in the summary. A `third_party` posting that fails another dimension goes to the excluded table with that reason, never to `代招岗位`.

Add a `City` column; do not group matched rows by city. Split matched rows into exactly two parts: `Easy Apply` (`easyApply: yes`) and `No Easy Apply` (everything else, including `unknown`). Within each part, put prompted rows first; in the No Easy Apply part prefix their Notes with `Top applicant`. Sort each part by `sortBy`/`sortDirection` (`companySize` uses the lower bound; default `asc`; ties keep discovery order). Renumber `#` after sorting. The split is a workflow split and never a filter. Easy Apply rows stay for the user; No Easy Apply rows are the ones `job-apply` fills.

Before writing, add cross-day repeat annotations from the index. Do not count excluded or expired jobs as repeats.

Publish when `reportRepo` is set: clone/pull it, copy the daily report to `reports/daily/YYYY-MM-DD.md`, commit `docs: add daily job results for YYYY-MM-DD`, push and verify. On failure, report it and keep the local file. Never force-push. Publish only the daily report.

After the report, update `reports/job-index.json`: upsert every inspected vacancy by source-qualified key; set `source`, `lastSeen`, `status`, `firstSeen`, `firstReportedOn`, `easyApply`, `applyType`, `coverLetter`, `posterType`, `business`; never clear `appliedOn` or any `apply*` field; do not write `isNeededCover` per vacancy. Append one JSON line to `reports/runs/YYYY-MM-DD.jsonl` using `runAt`, `finishedAt`, `durationSeconds` and the fields in `.opencode/skills/job-discovery/references/job-index-and-audit.md`. Preserve unknown fields; never delete entries.

If `applications.enabled` is `true`, load `job-apply` after the report and index are written and before the email summary. Discovery itself never applies.

If `notifications.email.enabled`, load `email-notify` and send one summary after the index and audit are written.

## 6. Report completion

State the report path, resolved scope (say `All Germany` when `locations` was empty), `jobSearchPrompt`, distinct vacancies inspected by source, applied-skipped, cards skipped before opening, expired/closed skipped, matched, Easy Apply-matched, No Easy Apply-matched, external applications filled/blocked, third-party postings (`代招岗位`), review, excluded, cross-day repeats, possible duplicates, per-source coverage and stop reason, email status and any access limitation.

Count only pages actually opened. Distinguish results seen from JDs reviewed. Do not add a limitations section to a normal report; use the exception note only for a failed or interrupted run.
