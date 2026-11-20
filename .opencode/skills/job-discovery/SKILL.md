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
- `jdLanguages.maxRequiredLevel` — optional map such as `{"German": "A2", "English": "C1"}`. Active only for the languages listed. It is a hard filter on explicit JD language requirements.
- `technicalKeywords.include`, `.matchMode` — stack matching.
- `preferredReportLanguage`, `reportRepo`, `notifications.email`, `sortBy`, `sortDirection`, `isNeededCover`.

Do not add a `search` wrapper or a second config file.

## 2. Resolve index and scope

Read the **previous daily report** (the most recent `reports/daily/YYYY-MM-DD.md` before today). Extract every job ID / canonical URL from all its tables (matched, `代招岗位`, review, excluded) into the **previous-report set**.

- Before opening a card, skip it if its job ID or canonical URL is in the previous-report set. Do not open, judge or list it; count it as `上次报告已记录（跳过）` / `previously reported (skipped)`.
- Applied jobs still count as applied-skipped.
- `skipPreviousReport` (config, default `true`) controls this. When `false`, no report-based skip.
- `reports/job-index.json` is **not** used for this decision. It is not a dedupe source.
- Explicit override: when the user asks to re-check specific jobs, a company or a status, exempt those for that run and record the exemption in `limitations`.
- If there is no previous daily report, the set is empty and every card is checked.
- Flag likely duplicates (same company, normalized title, city, different ID) as `⚠️ possible duplicate`; add `possibly applied MM-DD` when the other job was applied to.

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
3. Paginate until results fall outside `lookbackHours`. Deduplicate canonical URLs, skip jobs in the previous-report set and skip `appliedOn` jobs before opening. There is no inspection cap.
4. Skip a card without opening it only when its title clearly names another function and contains no configured role noun, or when it is clearly outside `countries`/`locations`. Open everything ambiguous.
5. Open the rest, prefer the canonical URL, and keep one record per vacancy tagged with `source`.

Use `jobSearchPrompt` verbatim on every platform. Do not rewrite, split, translate or append cities. Put it in the keyword field; set location from `countries`/`locations`.

Do not stop the whole run for one source failure. Record it in `limitations` and `searchedBySource`, continue, and report it. Never guess a private API, bypass login/CAPTCHA, or fabricate results. Discovery never applies, messages, saves or follows anything: Easy Apply is left to the user. For a matched external posting, discovery may open the employer apply form once to inspect its fields (read-only, no filling, no upload, no submit); filing happens only later in `job-apply`.

## 4. Inspect and classify

Open the posting once and confirm it is still open. In that same visit extract every field the report needs: title, company, company size, city, work mode, employment type, posted age, JD language and explicit language-requirement level, technical keywords (whole-word matches), poster type, business, `easyApply`, `applyType`, the visible cover-letter hint and the priority prompt. Never reopen a JD just to fill a missing report field; record `Not stated` / `unknown` / `review` instead.

Evaluate in order and stop at the first confirmed mismatch.

0. **Validity** — 404, redirect, or "no longer accepting applications" → skip as expired/closed.
1. **Job title** — same role family as `jobTitles.include`. Page title wins over card title.
2. **Poster type** — classify from the posting as `direct`, `third_party` or `unknown`. `third_party` means a staffing firm, headhunter, agency portal, "our client", "on behalf of", or the local-language equivalent (e.g. `im Auftrag`, `für unseren Kunden`, `Arbeitnehmerüberlassung`). A consultancy hiring for its own projects is `direct`. Unclear → `unknown`. With `thirdPartyPostings: exclude`, a confirmed `third_party` is `not_matched` and stops here; with `separate` or `include`, continue and let the remaining checks decide. `third_party` is never a bypass: steps 3–7 must still confirm every active filter.
3. **JD language** — in `jdLanguages.include`. A German JD matches when `acceptGermanJdWithEnglishWorkingLanguage` is `true` and the JD names English as the working language. Mixed, short or truncated → `unknown`.
3b. **Language requirement level** — only when `jdLanguages.maxRequiredLevel` has an entry for that language. Extract explicit requirements from the JD, e.g. `German C1`, `Deutschkenntnisse B2`, `fließend Deutsch`, `verhandlungssicher`, `English fluent`, `business fluent`. Map to CEFR: A1 < A2 < B1 < B2 < C1 < C2. `basic`/`Grundkenntnisse` → A2; `good`/`gute`/`solid` → B1; `business fluent` → B2; `fluent`/`fließend`/`verhandlungssicher` → C1; `native`/`muttersprachlich` → C2. A bare `German required` / `Deutsch erforderlich` / `Deutschkenntnisse` with no level counts as B1. A phrase such as `nice to have`, `plus`, `von Vorteil` or `optional` is not a requirement. Use the highest requirement stated for that language. A requirement strictly above the configured level is a confirmed mismatch → `not_matched` with reason `language requirement: <language> <required> > <configured>`. A requirement at or below the configured level passes. Ambiguous wording that cannot be mapped to a level → `unknown` → review, not matched.
4. **Technical keywords** — follow `matchMode`; accept JS/JavaScript, TS/TypeScript, NodeJS/Node.js, ReactJS/React. With `any`, stop at the first hit.
5. **Work mode** — only when `workModes` is a real subset. Missing → `unknown`.
6. **Employment type** — only when `employmentTypes` is a real subset. Missing → `unknown`.
7. **Seniority** — only when `seniority.include` is a real subset. Use title or explicit level, never bare years. Missing → `unknown`.
8. **Company business** — informational, never a filter. Record one short phrase only when the JD explicitly states the company's product, market or industry; otherwise `Not stated`. Never infer it from the company name, domain, another page or general knowledge.

Disabled checks are skipped. Confirmed mismatch → `not_matched`, stop. Any `unknown` with no mismatch → `review`. Otherwise `matched`.

**Third-party gate.** Only a `third_party` posting with a confirmed `matched` result on every active dimension may enter `代招岗位`. A confirmed mismatch in title, JD language, language requirement level, technical keywords, work mode, employment type or seniority sends it to Excluded with that reason. An `unknown` in any of those dimensions sends it to review, never to `代招岗位`. Never assume full-time, English JD, on-site/hybrid, a seniority level or a language from the poster type alone.

Record `easyApply` (`yes`/`no`/`unknown`), `applyType` (`easy_apply` when the button applies inside the platform, `external` when it clearly redirects to an employer/ATS page, `unknown` otherwise) and `coverLetter` (`yes`/`no`/`unknown`) for every inspected vacancy. These are informational and never affect classification.

**Apply-form inspection.** For a `matched` vacancy whose Apply control leaves the platform (`applyType: external`), open the employer form once and record: ATS name and host, final `applyUrl`, login/account/CAPTCHA/file blockers, and every visible field with its label, type, required flag, options and the value that would be filled from `applicant`/`applications.screening`. Record the cover-letter field as required, optional or absent. Never type into the form, never upload a file, never click Submit; close the inspection tab when done. If the form cannot be reached or is login-walled, record the blocker and continue. Easy Apply is never opened.

Keep the search tab and reuse one detail tab. Close every JD and apply-form tab immediately after that vacancy's row (including its field table and cover letter) is written to the report; never batch-close at the end. Close the apply-form tab even when the form is blocked.

Record `posterType` for every inspected vacancy that reaches the report. Record `business` only from an explicit JD statement. For a `third_party` posting, `business` describes the client employer's business when the JD states it; the client employer goes in Notes.

Record the platform priority prompt when the reference defines one and the config enables it (LinkedIn: `linkedinPremium`). It only orders rows. Recorded `easyApply` is also ordering metadata only and never a filter.

Keep `matched` and `review`; exclude `not_matched` from the main report. Never score fit. Do not filter on years, salary, visa, industry, architecture or company size. The only language-level filter is the explicit `jdLanguages.maxRequiredLevel` rule above; never infer a language level from the JD language, the company or the candidate's nationality. Record only page facts.

Draft a cover letter for every `matched` or `review` vacancy whose apply form shows a cover-letter field, whether it is required or optional, when `isNeededCover` is `true`. A `Message to the Hiring Team` / `Message to the team` textarea counts as a cover-letter field: write a shortened 3–5 sentence text version, save it as `reports/cover-letters/<company-slug>/<jobId>-message.md`, and put the text in the report; do not create a PDF for it. For a real cover-letter upload, use the `cover-letter` skill and `cover-letter-template.md` exactly: keep structure, sections, wording and order; fill only its placeholders from the page and config; leave unfillable placeholders unchanged and tell the user. Never fabricate. Save `cover-letter.json` plus `<jobId>.pdf` (and `<jobId>.md` when a text-only letter is needed); `<company-slug>`: lowercase, spaces/punctuation → `-`. Record the path in the report and index. Do not upload or submit it. If the template is missing, stop that step and tell the user to copy `cover-letter-template-example.md`.

## 5. Write the report

Follow `.opencode/skills/job-discovery/references/daily-report-format.md` for structure, sections, columns, metadata and summaries. Write human-readable strings in `preferredReportLanguage`; keep structure, order, dates and URLs unchanged.

Write `reports/daily/YYYY-MM-DD.md`. Merge with an existing report. Preserve any `代招岗位` and `Feed-sourced jobs` sections and their counts. Deduplicate by canonical URL; without one, use company + title + location and flag possible duplicates.

When `thirdPartyPostings` is `separate`, put only confirmed `third_party` postings that pass every active filter in the dedicated `代招岗位` section, with the same columns, keyword evidence, ordering and checks as matched jobs. They count as matched in the summary. A `third_party` posting that fails title, JD language, language requirement level, technical keywords, work mode, employment type or seniority goes to the excluded table with that reason, never to `代招岗位`. A third-party posting with `unknown` on an active dimension goes to review, never to `代招岗位`.

Add a `City` column; do not group matched rows by city. Split matched rows into exactly two parts: `Easy Apply` (`easyApply: yes`) and `No Easy Apply` (everything else, including `unknown`). Within each part, put prompted rows first; in the No Easy Apply part prefix their Notes with `Top applicant`. Sort each part by `sortBy`/`sortDirection` (`companySize` uses the lower bound; default `asc`; ties keep discovery order). Renumber `#` after sorting. The split is a workflow split and never a filter. Easy Apply rows stay for the user; No Easy Apply rows carry the inspected apply-form fields.

Before writing, add cross-day repeat annotations only for jobs exempted from the previous-report skip. Do not count excluded or expired jobs as repeats.

Publish when `reportRepo` is set: clone/pull it, copy the daily report to `reports/daily/YYYY-MM-DD.md`, commit `docs: add daily job results for YYYY-MM-DD`, push and verify. On failure, report it and keep the local file. Never force-push. Publish only the daily report.

After the report, update `reports/job-index.json`: upsert every inspected vacancy by source-qualified key; set `source`, `lastSeen`, `status`, `firstSeen`, `firstReportedOn`, `easyApply`, `applyType`, `coverLetter`, `posterType`, `business`, `applyChannel`, `applyUrl`, `applyForm` and `coverLetterDraft`; never clear `appliedOn` or any `apply*` field; do not write `isNeededCover` per vacancy. Append one JSON line to `reports/runs/YYYY-MM-DD.jsonl` using `runAt`, `finishedAt`, `durationSeconds` and the fields in `.opencode/skills/job-discovery/references/job-index-and-audit.md`. Preserve unknown fields; never delete entries.

`applyForm` is `inspected` / `blocked` / `not_external`; `coverLetterDraft` is the saved file path or empty. Discovery records the form; it never files it.

If `applications.enabled` is `true` and `applications.externalApply` is `true`, `"fill"` or `"submit"`, load `job-apply` after the report and index are written and before the email summary. With `false`, `"inspect"` or `"off"`, the apply form is inspected inline and `job-apply` is not loaded. Discovery itself never fills or submits, and never opens a LinkedIn Easy Apply form.

If `notifications.email.enabled`, load `email-notify` and send one summary after the index and audit are written.

## 6. Report completion

State the report path, resolved scope (say `All Germany` when `locations` was empty), `jobSearchPrompt`, distinct vacancies inspected by source, applied-skipped, previously-checked skipped, cards skipped before opening, expired/closed skipped, matched, Easy Apply-matched, No Easy Apply-matched, external applications filled/blocked, third-party postings (`代招岗位`), review, excluded, cross-day repeats, possible duplicates, per-source coverage and stop reason, email status and any access limitation.

Count only pages actually opened. Distinguish results seen from JDs reviewed. Do not add a limitations section to a normal report; use the exception note only for a failed or interrupted run.
