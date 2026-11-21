---
name: job-discovery
description: Search the platforms in sources with the local browser, inspect real JDs, filter by title, JD language, technical keywords, work mode, employment type and optional seniority, separate confirmed third-party postings unless configured otherwise, record explicit company business, verify the posting is open, and write the daily report.
---

# Job Discovery

Run locally in this repository. Use the configured browser tools. Do not add a backend, database, CLI, CI or source adapters.

## 1. Read config

Read `job-hunter.config.json`. It is the single runtime config and is Git-ignored. Never use `job-hunter.config.example.json` as the user's preferences.

If the personal config is missing, tell the user to copy the example, customize it, and stop.

The config has three layers. Read the layer you need; never invent a parallel key.

1. `sources` — required platform list. **This array is the run order.** Each entry needs a matching `platforms.<name>` block.
2. `common` — preferences shared by every platform:
   - `common.countries` — required scope boundary. It does not build the query.
   - `common.locations` — optional city refinement. Empty = whole country.
   - `common.lookbackHours`, `common.workModes`, `common.employmentTypes`, `common.seniority.include` — scope and optional filters.
   - `common.thirdPartyPostings` — `separate` (default) keeps confirmed third-party postings in the dedicated `代招岗位` section, `include` lists them with normal matches, `exclude` drops them.
   - `common.skipPreviousReport` (default `true`).
   - `common.jobSearchPrompt` — the natural-language query used by platforms whose `queryMode` is `prompt`.
   - `common.jobTitles.include`, `common.jdLanguages.*`, `common.technicalKeywords.*` — matching dimensions.
   - `common.sortBy`, `common.sortDirection`, `common.preferredReportLanguage`, `common.reportRepo`, `common.isNeededCover`.
   - `common.dedupe.crossSource` (default `true`) — treat the same company + title + city on two platforms as one vacancy.
   - `common.dedupe.skipApplied` (default `true`) — once a vacancy is applied to on any platform, skip it on every other platform and never apply again.
   - `common.report.splitBySource` (default `true`) — group the daily report by source, in `sources` order.
3. `platforms.<name>` — platform-only settings:
   - `platforms.LinkedIn`: `enabled`, `premium`, `search.queryMode`, `feedReview`, `feedJobs`.
   - `platforms.Indeed`: `enabled`, `domain`, `search.queryMode`, `search.queries`, `search.maxQueries`, `search.maxPagesPerQuery`, `search.lookbackHours`, `search.filters` (`date`, `employmentType`, `language`, `remote`, `quickApply`).
   - `search.queryMode` is `prompt` (use `common.jobSearchPrompt` verbatim, the default), `titles` (one query per `common.jobTitles.include` entry) or `custom` (use `search.queries`). A platform's `search.lookbackHours` overrides `common.lookbackHours` for that platform only.
4. Shared runtime, not search preferences: `applicant`, `applications`, `notifications`.
5. `schedules.jobSearch`, `schedules.linkedinFeedReview` — launchd blocks. They never change how a run searches.

Do not add a second config file. A platform named in `sources` without a `platforms` block is a config error: name it in `limitations` and continue with the others.

## 2. Resolve index and scope

**One run = one report file.** At run start record the local start time and derive the report path `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM.md` (`HHMM` = start time; add `-2`, `-3` on a same-minute collision). Never append to or rewrite another run's report.

Read the **previous-report set** from:

- every run report of today whose `HHMM` is earlier than this run's start (`reports/daily/YYYY-MM-DD/YYYY-MM-DD-*.md`) — a 20:40 run must treat the 15:40 run as a hard skip — and
- every run report of the most recent previous date.

Extract every job ID / canonical URL from all their tables (matched, `代招岗位`, review, submitted, excluded) into the set.

- Before opening a card, skip it if its job ID or canonical URL is in the previous-report set. Do not open, judge or list it; count it as `上次报告已记录（跳过）` / `previously reported (skipped)`.
- `common.skipPreviousReport` (default `true`) controls this. When `false`, no report-based skip.
- `reports/job-index.json` is **not** the source for this previous-report skip; it is only used for the applied set and cross-source dedup below.
- Explicit override: when the user asks to re-check specific jobs, a company or a status, exempt those for that run, append `[reported MM-DD HH:MM]` pointing at the earlier run and record the exemption in `limitations`.
- If no earlier run report exists, the set is empty and every card is checked.
- Flag likely duplicates (same company, normalized title, city, different ID) as `⚠️ possible duplicate`; add `possibly applied MM-DD` when the other job was applied to.

Read the index once for the whole run and build two in-memory sets before any platform is opened:

- **applied set** — every index job with `appliedOn` set or `applyStatus` in `submitted` / `filled`, plus every `Submitted` / `Filled (awaiting submit)` row in the last 30 days of `reports/applications/*.md`, keyed by normalized `company + title + city` (normalization: `job-index-and-audit.md` §4).
- **known set** — every index job that is `matched` or `review`, same key, used for soft-duplicate annotations.

These sets are shared across platforms and are the basis for the cross-source rule in §2a. Write the result into the report's run header (`投递查重` line): entries checked, this run's applied hits, skipped count. **Never submit a vacancy that is already in the applied set, whatever URL or platform it appears under.**

Resolve scope:

1. Require one non-empty `common.countries` entry; otherwise stop and ask.
2. `common.locations` non-empty = those country × city combinations only.
3. `common.locations` empty = the entire configured country. Do not narrow silently.
4. State the resolved scope in the final summary.

Only title, JD language, technical keywords, work modes, employment types and seniority are matching filters. Poster type is a display split for confirmed third-party postings (or an exclusion only when `common.thirdPartyPostings` is `exclude`). Country, city and posting date are scope. Validity is a gate.

If the user gives one-run criteria in chat, restate them and apply them to that run only.

## 2a. Cross-source rule

`common.dedupe` decides how the same vacancy is treated on two platforms. Both keys default to `true`.

- `crossSource: true` — normalize `company + title + city` and treat the two cards as the same vacancy. Annotate the second one with `⚠️ 同职位已在 <source> 出现` (`⚠️ same job on <source>`) and keep the first one. Never merge rows, never change a decision.
- `skipApplied: true` — before opening a card on platform B, look its normalized key up in the applied set. When the hit comes from **another** platform, do not open it, do not list it, and never apply again: count it as `已在其他平台投递（跳过）` / `applied on another platform (skipped)`. When the hit comes from the same platform, count it as the normal applied-skip.
- Build the applied set from the index **before** the first platform and extend it during the run: an application confirmed in platform A's step is immediately visible to platform B, which runs later in `sources` order.
- The cross-source skip is a scope rule, not a match rule: it never creates a `matched`, `review` or `excluded` row.
- With `crossSource: false`, only the canonical URL/ID dedupe applies and the two platforms are treated as unrelated.

## 3. Search sources

Read the platform reference before searching. Use this map:

| Source | Reference |
|---|---|
| `LinkedIn` | `references/linkedin.md` |
| `Indeed` | `references/indeed.md` |
| new platform | `references/_template.md` |

Match case-insensitively and ignore a country domain. Never improvise a flow for a platform without a reference; skip it, name it and continue.

If no browser tool exists, stop and say so. If `sources` is empty, ask which platforms to use.

Skip a source whose `platforms.<name>.enabled` is not `true`; count it as `skipped (disabled)` and continue. A caller may also scope a pass to a subset of `sources` (for example "LinkedIn only"): process just those in `sources` order, count the rest as `skipped (not in this pass)`, do not mark them failed, and never open a platform outside the pass. At the start record the local start time in ISO 8601 with offset as `runAt` and derive this run's report path (`reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM.md`); both go into the report header and the audit line.

For each source in `sources` order:

1. Resolve that platform's queries from `platforms.<name>.search`:
   - `queryMode: "prompt"` — submit `common.jobSearchPrompt` once, verbatim.
   - `queryMode: "titles"` — submit one short query per entry of `common.jobTitles.include`, in order, capped at `maxQueries`.
   - `queryMode: "custom"` — submit `search.queries` in order, capped at `maxQueries`.
   Never rewrite, split or translate a query. Never append cities; the location comes from `common.countries`/`common.locations`.
2. Apply the date-posted filter from the effective lookback (`search.lookbackHours` when set, otherwise `common.lookbackHours`) and verify it is active — date is scope and is always applied. Then apply only the matching filters this platform enables in `search.filters` (`employmentType`, `language`, `remote`, `quickApply`). Any dimension whose flag is `false` is read from each posting instead.
3. Paginate until results fall outside the window, up to `maxPagesPerQuery` when set. Deduplicate canonical URLs and job IDs, skip jobs in the previous-report set, skip `appliedOn` jobs and skip cross-source applied jobs (§2a) before opening. There is no inspection cap beyond the per-platform page cap.
4. Skip a card without opening it only when its title clearly names another function and contains no configured role noun, or when it is clearly outside `common.countries`/`common.locations`. Open everything ambiguous.
5. Open the rest, prefer the canonical URL, and keep one record per vacancy tagged with `source`. Finish every platform before starting the next one.

**Strictly sequential — one query, one posting, one tab.** This is mandatory on every platform, Indeed included:

- One query at a time. Finish all its pages before submitting the next query.
- One posting at a time. Open exactly one detail tab, read the JD, classify it, take the apply/inspect action, write the row, close that tab, then open the next posting.
- Never batch-open cards or collect several job URLs and open them together.
- Never loop over multiple job IDs inside a single tool call or script.
- Never run two browser actions in parallel and never keep more than one job tab open.
- A slow, serial pass is correct; a fast batch pass is a defect even when it produces the same rows.

A platform's search results are not proof of a match: recommendation and fallback blocks ignore the active filters. Always judge each posting from its own page.

Do not stop the whole run for one source failure. Record it in `limitations` and `searchedBySource`, continue, and report it. Never guess a private API, bypass login/CAPTCHA, or fabricate results.

**Exception — stop everything.** A platform trust or automation-suspicion signal (`verify you are human`, CAPTCHA, `unusual activity` / `unusual traffic`, `automated access`, `are you a robot`, an AI-agent warning, or a forced re-login/2FA triggered mid-run) is not a normal source failure. Stop the entire run immediately: do not open another card, do not search another query or platform, do not apply, do not retry. Keep everything already written, record the platform plus the exact dialog text in `limitations` and the exception note, and tell the user to take over.

Discovery never applies, messages, saves or follows anything: a platform's own one-click apply is left to the user. For a matched external posting, discovery may open the employer apply form once to inspect its fields (read-only, no filling, no upload, no submit); filing happens only later in `job-apply`.

## 4. Inspect and classify

Open the posting once and confirm it is still open. In that same visit extract every field the report needs: title, company, company size, city, work mode, employment type, posted age, JD language and explicit language-requirement level, technical keywords (whole-word matches), poster type, business, `easyApply`, `applyType`, the visible cover-letter hint and the priority prompt. Never reopen a JD just to fill a missing report field; record `Not stated` / `unknown` / `review` instead.

Evaluate in order and stop at the first confirmed mismatch.

0. **Validity** — 404, redirect, or "no longer accepting applications" → skip as expired/closed.
1. **Job title** — strict. The page title (not the card title) must contain one entry of `common.jobTitles.include` as a whole phrase, after lowercasing and removing gender markers and punctuation. Expand only these abbreviations before comparing: `TS` → `TypeScript`, `JS` → `JavaScript`, `Dev` → `Developer`, `Sr.` → `Senior`, `Jr.` → `Junior`. A title containing any word from `common.jobTitles.excludeWords` (`lead`, `staff`, `principal`, `head of`, `manager`, `architect`, `cto`, `director`, `vp` by default) is a confirmed mismatch, even when a configured title also appears. Never widen the family because of words like "frontend focus" or "fullstack" in the title.
2. **Poster type** — classify from the posting as `direct`, `third_party` or `unknown`. `third_party` means a staffing firm, headhunter, agency portal, "our client", "on behalf of", or the local-language equivalent (e.g. `im Auftrag`, `für unseren Kunden`, `Arbeitnehmerüberlassung`). A consultancy hiring for its own projects is `direct`. Unclear → `unknown`. With `common.thirdPartyPostings: exclude`, a confirmed `third_party` is `not_matched` and stops here; with `separate` or `include`, continue and let the remaining checks decide. `third_party` is never a bypass: steps 3–7 must still confirm every active filter.
3. **JD language** — in `common.jdLanguages.include`. A German JD matches when `common.jdLanguages.acceptGermanJdWithEnglishWorkingLanguage` is `true` and the JD names English as the working language. Mixed, short or truncated → `unknown`.
3b. **Language requirement level** — only when `common.jdLanguages.maxRequiredLevel` has an entry for that language. Extract explicit requirements from the JD, e.g. `German C1`, `Deutschkenntnisse B2`, `fließend Deutsch`, `verhandlungssicher`, `English fluent`, `business fluent`. Map to CEFR: A1 < A2 < B1 < B2 < C1 < C2. `basic`/`Grundkenntnisse` → A2; `good`/`gute`/`solid` → B1; `business fluent` → B2; `fluent`/`fließend`/`verhandlungssicher` → C1; `native`/`muttersprachlich` → C2. A bare `German required` / `Deutsch erforderlich` / `Deutschkenntnisse` with no level counts as B1. A phrase such as `nice to have`, `plus`, `von Vorteil` or `optional` is not a requirement. Use the highest requirement stated for that language. A requirement strictly above the configured level is a confirmed mismatch → `not_matched` with reason `language requirement: <language> <required> > <configured>`. A requirement at or below the configured level passes. Ambiguous wording that cannot be mapped to a level → `unknown` → review, not matched.
4. **Technical keywords** — follow `common.technicalKeywords.matchMode`; accept JS/JavaScript, TS/TypeScript, NodeJS/Node.js, ReactJS/React. With `any`, stop at the first hit.
5. **Work mode** — only when `common.workModes` is a real subset. Missing → `unknown`.
6. **Employment type** — only when `common.employmentTypes` is a real subset. Missing → `unknown`.
7. **Seniority** — only when `common.seniority.include` is a real subset. Use title or explicit level, never bare years. Missing → `unknown`.
8. **Company business** — informational, never a filter. Record one short phrase only when the JD explicitly states the company's product, market or industry; otherwise `Not stated`. Never infer it from the company name, domain, another page or general knowledge.

Disabled checks are skipped. Confirmed mismatch → `not_matched`, stop. Any `unknown` with no mismatch → `review`. Otherwise `matched`.

**Third-party gate.** Only a `third_party` posting with a confirmed `matched` result on every active dimension may enter `代招岗位`. A confirmed mismatch in title, JD language, language requirement level, technical keywords, work mode, employment type or seniority sends it to Excluded with that reason. An `unknown` in any of those dimensions sends it to review, never to `代招岗位`. Never assume full-time, English JD, on-site/hybrid, a seniority level or a language from the poster type alone.

Record `easyApply` (`yes`/`no`/`unknown`), `applyType` (`easy_apply` when the button applies inside the platform, `external` when it clearly redirects to an employer/ATS page, `unknown` otherwise) and `coverLetter` (`yes`/`no`/`unknown`) for every inspected vacancy. These are informational and never affect classification.

**Apply-form inspection.** For a `matched` vacancy whose Apply control leaves the platform (`applyType: external`), open the employer form once and record: ATS name and host, final `applyUrl`, login/account/CAPTCHA/file blockers, and every visible field with its label, type, required flag, options and the value that would be filled from `applicant`/`applications.screening`. Record the cover-letter field as required, optional or absent. Never type into the form, never upload a file, never click Submit; close the inspection tab when done. If the form cannot be reached or is login-walled, record the blocker and continue. A platform one-click apply form is never opened.

Keep the search tab and reuse one detail tab. Close every JD and apply-form tab immediately after that vacancy's row (including its field table and cover letter) is written to the report; never batch-close at the end. Close the apply-form tab even when the form is blocked.

Record `posterType` for every inspected vacancy that reaches the report. Record `business` only from an explicit JD statement. For a `third_party` posting, `business` describes the client employer's business when the JD states it; the client employer goes in Notes.

Record the platform priority prompt when the reference defines one and the config enables it (LinkedIn: `platforms.LinkedIn.premium`). It only orders rows. Recorded `easyApply` is also ordering metadata only and never a filter.

Keep `matched` and `review`; exclude `not_matched` from the main report. Never score fit. Do not filter on years, salary, visa, industry, architecture or company size. The only language-level filter is the explicit `common.jdLanguages.maxRequiredLevel` rule above; never infer a language level from the JD language, the company or the candidate's nationality. Record only page facts.

Draft a cover letter for **every matched vacancy** — `Easy Apply` and `No Easy Apply` alike, and every `代招岗位` row — whether or not the form exposes a cover-letter field, whenever `common.isNeededCover` is `true`. Generation is unconditional; only the upload follows `applications.coverLetterMode`. For a `代招岗位` row, use only facts the post states; never invent the client. A `Message to the Hiring Team` / `Message to the team` textarea counts as a cover-letter field: write a shortened 3–5 sentence text version, save it as `reports/cover-letters/<company-slug>/<jobId>-message.md`, and put the text in the report; do not create a PDF for it. For a real cover-letter upload, use the `cover-letter` skill and `cover-letter-template.md` exactly: keep structure, sections, wording and order; fill only its placeholders from the page and config; leave unfillable placeholders unchanged and tell the user. Never fabricate. Save the letter JSON plus `<First>_<Last>_<Role>_Cover_Letter.pdf` (and the matching `.md` when a text-only letter is needed); `<company-slug>`: lowercase, spaces/punctuation → `-`. Record the path in the report and index. Do not upload or submit it. If the template is missing, stop that step and tell the user to copy `cover-letter-template-example.md`.

## 5. Write the report

Follow `.opencode/skills/job-discovery/references/daily-report-format.md` for structure, sections, columns, metadata and summaries. Write human-readable strings in `common.preferredReportLanguage`; keep structure, order, dates and URLs unchanged.

Write **this run's own file**, `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM.md` (`HHMM` = this run's start time, `-2` / `-3` on collision). Create it fresh with the run header (run id, start time, end time, sources of this run, scope, apply-dedupe result). Never append to an earlier run's file and never write a day-total report. Deduplicate inside the file by canonical URL; without one, use company + title + location and flag possible duplicates.

When `common.thirdPartyPostings` is `separate`, put only confirmed `third_party` postings that pass every active filter in the dedicated `代招岗位` section, with the same columns, keyword evidence, ordering and checks as matched jobs. They count as matched in the summary. A `third_party` posting that fails title, JD language, language requirement level, technical keywords, work mode, employment type or seniority goes to the excluded table with that reason, never to `代招岗位`. A third-party posting with `unknown` on an active dimension goes to review, never to `代招岗位`.

Add a `City` column; do not group matched rows by city. When `common.report.splitBySource` is `true` (default), write one section per source **in `sources` order** (LinkedIn first, then Indeed), and inside each source split matched rows into two parts: `Easy Apply` (`easyApply: yes`, not submitted) and `No Easy Apply` (everything else, including `unknown`, not submitted). Submitted rows leave the source sections for a single global `已提交` section just before the excluded table. `#` restarts at 1 in every source section. When the flag is `false`, keep the single merged matched table with the same two parts and continuous numbering.

Within each part, put prompted rows first among the non-submitted rows; in the No Easy Apply part prefix their Notes with `Top applicant`. A row whose application was submitted leaves its source section and moves to the global `已提交` section just before the excluded table, so submitted rows never sit among inspected ones. Every external row that was not submitted ends its Notes with `无法自动提交：<reason>`. Sort each part by `common.sortBy`/`common.sortDirection` (`companySize` uses the lower bound; default `asc`; ties keep discovery order). Renumber `#` after sorting. The split is a workflow split and never a filter. Easy Apply rows stay for the user; No Easy Apply rows carry the inspected apply-form fields.

Cross-source rows follow §2a: a vacancy already applied to on another platform is counted as skipped and never listed; a cross-source duplicate that was not applied to is annotated, never merged.

Before writing, add cross-day repeat annotations only for jobs exempted from the previous-report skip. Do not count excluded or expired jobs as repeats.

Publish when `common.reportRepo` is set: clone/pull it, create the day folder `reports/<YYYY-MM-DD>/` in that repo, copy this run's report there as `YYYY-MM-DD-HHMM.md`, commit `docs: add job run YYYY-MM-DD HH:MM`, push and verify. Never merge two runs into one remote file and never overwrite another run's file. On failure, report it and keep the local file. Never force-push. Publish only the run report.

After the report, update `reports/job-index.json`: upsert every inspected vacancy by source-qualified key; set `source`, `lastSeen`, `status`, `firstSeen`, `firstReportedOn`, `easyApply`, `applyType`, `coverLetter`, `posterType`, `business`, `applyChannel`, `applyUrl`, `applyForm` and `coverLetterDraft`; never clear `appliedOn` or any `apply*` field; do not write `common.isNeededCover` per vacancy. At the very end of the run append one JSON line to `reports/runs/YYYY-MM-DD.jsonl` with the real `runAt`, `finishedAt`, `durationSeconds`, this run's `reportPath` and the fields in `.opencode/skills/job-discovery/references/job-index-and-audit.md`. Never write `finishedAt` in advance. Preserve unknown fields; never delete entries.

`applyForm` is `inspected` / `blocked` / `not_external`; `coverLetterDraft` is the saved file path or empty. Discovery records the form; it never files it.

If `applications.enabled` is `true` and `applications.externalApply` is `true`, `"fill"` or `"submit"`, load `job-apply` after the report and index are written and before the email summary. With `false`, `"inspect"` or `"off"`, the apply form is inspected inline and `job-apply` is not loaded. Discovery itself never fills or submits, and never opens a platform one-click apply form (LinkedIn Easy Apply, Indeed Apply / Schnellbewerbung).

If `notifications.email.enabled`, load `email-notify` and send one summary after the index and audit are written.

## 6. Report completion

State the report path (the run file with its exact start time), resolved scope (say `All Germany` when `common.locations` was empty), the resolved queries per source, distinct vacancies inspected by source, applied-skipped, applied-on-another-platform skipped, previously-checked skipped, cards skipped before opening, expired/closed skipped, matched, Easy Apply-matched, No Easy Apply-matched, external applications filled/blocked, third-party postings (`代招岗位`), review, excluded, cross-day repeats, possible duplicates, per-source coverage and stop reason, email status and any access limitation. Give the counts per source and as a total for this run only.

Count only pages actually opened. Distinguish results seen from JDs reviewed. Do not add a limitations section to a normal report; use the exception note only for a failed or interrupted run.
