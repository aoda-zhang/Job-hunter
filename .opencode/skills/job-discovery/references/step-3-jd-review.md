# Step 3 — JD review

Read this file after step 2. Open the `sent to JD review` rows one at a time, in `job-audit` order, and classify each from its own page.

## 1. Open once

1. Open the canonical URL, prefer the canonical URL, and confirm the posting is still open.
2. In that same visit extract: title, company, company size, city, work mode, employment type, posted age, JD language and explicit language-requirement level, technical keywords, poster type, business, `easyApply`, `applyType`, cover-letter hint, top-applicant marker.
3. Never reopen a JD for a missing report field — write `Not stated` / `unknown` / `review` instead.
4. Keep the search tab and reuse one detail tab. Close every JD and apply-form tab immediately after its row is written.

Strictly sequential: one posting, one tab, one row at a time.

## 2. Checks, in order — stop at the first confirmed mismatch

0. **Validity** — 404, redirect, or "no longer accepting applications" → expired/closed, skip.
1. **Job title** — strict. The page title (not the card) must contain one entry of `common.jobTitles.include` as a whole phrase, after lowercasing and stripping gender markers and punctuation. Translate a non-English title first — this is a title gate, not a language gate:
   - `Entwickler`/`Entwicklerin`/`Entwicklung` → `Developer`; `Ingenieur` → `Engineer`; `Softwareentwickler` → `Software Engineer`; `Frontend-Entwickler` → `Frontend Developer`; `Webentwickler` → `Web Developer`; `Fullstack-Entwickler` → `Fullstack Developer`; `Anwendungsentwickler` → `Application Developer`.
   - `Developer` = `Engineer`; `TS` → `TypeScript`, `JS` → `JavaScript`, `Dev` → `Developer`, `Sr.` → `Senior`, `Jr.` → `Junior`.
   - A title containing any `jobTitles.excludeWords` word is a confirmed mismatch even when a configured title also appears. Never widen the family for "frontend focus" or "fullstack".
2. **Poster type** — `direct`, `third_party` or `unknown`. `third_party` = staffing firm, headhunter, agency portal, "our client", "on behalf of", `im Auftrag`, `für unseren Kunden`, `Arbeitnehmerüberlassung`. A consultancy hiring for its own projects is `direct`. Unclear → `unknown`. With `thirdPartyPostings: exclude`, a confirmed `third_party` stops here as `not_matched`; with `separate` or `include`, continue — poster type is never a bypass.
3. **JD language** — in `common.jdLanguages.include`. A German JD matches when `acceptGermanJdWithEnglishWorkingLanguage` is `true` and the JD names English as the working language. Mixed, short or truncated → `unknown`.
4. **Language requirement level** — only when `maxRequiredLevel` has an entry for that language. Map to CEFR: A1 < A2 < B1 < B2 < C1 < C2. `basic`/`Grundkenntnisse` → A2; `good`/`gute`/`solid` → B1; `business fluent` → B2; `fluent`/`fließend`/`verhandlungssicher` → C1; `native`/`muttersprachlich` → C2. Bare `German required` / `Deutschkenntnisse` = B1. `nice to have`, `plus`, `von Vorteil`, `optional` are not requirements. Use the highest stated level. Above the configured level → `not_matched` with `language requirement: <language> <required> > <configured>`; at or below → passes; unmappable → `unknown` → review.
5. **Technical keywords** — per `technicalKeywords.matchMode`; accept JS/JavaScript, TS/TypeScript, NodeJS/Node.js, ReactJS/React. With `any`, stop at the first hit.
6. **Work mode** — only when `workModes` is a real subset. Missing → `unknown`.
7. **Employment type** — only when `employmentTypes` is a real subset. Missing → `unknown`.
8. **Seniority** — only when `seniority.include` is a real subset. Use title or explicit level, never bare years.
9. **Company business** — informational. One short phrase only when the JD states the product, market or industry; otherwise `Not stated`. Never infer it.

Disabled checks are skipped. Confirmed mismatch → `not_matched`, stop. Any `unknown` with no mismatch → `review`. Otherwise `matched`.

**Third-party gate.** Only a `third_party` posting matched on every active dimension enters the agency/third-party section. A confirmed mismatch goes to Excluded with that reason; an `unknown` goes to review. Never assume full-time, English JD, work mode or seniority from the poster type.

## 3. Apply control

Record `easyApply` (`yes` / `no` / `unknown`), `applyType` (`easy_apply` / `external` / `unknown`) and `coverLetter` (`yes` / `no` / `unknown`) for every inspected vacancy. They never affect classification.

- `easy_apply` — open the one-click form once, read-only, record every visible field (label, type, required, options, mapped value) into `<run>/<Company>-<JobTitle>/fields.json`, close it. **Never type, upload or submit.** The row stays with the user.
- `external` — click Apply once, confirm the destination leaves the platform, and inspect the employer form read-only: ATS, host, final `applyUrl`, blockers and every field into `fields.json`. `job-apply` files it after the report; a blocker is written by `job-apply` as `blocked: <reason>` in `fields.json` plus one row in `.opencode/skills/job-apply/help.md` (`Status: open`).
- `unknown` — do not click; record it and leave the row for the user.

The daily report carries only the short `Apply form` status, never a field table.

## 4. Cover letters

Draft a cover letter for **every matched vacancy** — Easy Apply, external and every agency/third-party row — whenever `common.isNeededCover` is `true`, whether or not the form exposes a field.

- Generation is unconditional; only the upload follows `applications.coverLetterMode`.
- The letter is always written in **English**, whatever `common.preferredReportLanguage` says.
- A `Message to the Hiring Team` textarea counts as a cover-letter field: save a shortened 3–5 sentence version as `<run>/<Company>-<JobTitle>/message.md` and put the text in the report; no PDF.
- For a real upload use the `cover-letter` skill and template exactly — fill only placeholders, never invent, leave unfillable placeholders unchanged and tell the user.
- Save the JSON plus `<First>_<Last>_<Role>_Cover_Letter.pdf` and record the path. Never upload or submit it.
- If the template is missing, stop that step and tell the user to copy `cover-letter-template-example.md`.

## 5. Output

- `matched` and `review` rows go to the report tables; `not_matched` goes to the excluded table. Every row that was inspected is recorded in this run's report and audit only.
- Record `posterType` for every inspected vacancy; record `business` only from an explicit JD statement. For `third_party`, the client goes in Notes.
- Read the top-applicant marker only when the platform reference defines it and the config enables it (LinkedIn: `platforms.LinkedIn.premium`). It orders rows and is never a check.
- Never score fit, never filter on years, salary, visa, industry, architecture or company size. Record only page facts.

Report structure and columns: `daily-report-format.md`.
