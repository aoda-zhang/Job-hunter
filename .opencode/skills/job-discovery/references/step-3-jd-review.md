# Step 3 — JD review

Read this file after step 2. Open the `sent to JD review` rows one at a time, in `job-audit` order, and classify each from its own page.

## 1. Open once

1. Open the canonical URL, prefer the canonical URL, and confirm the posting is still open.
2. In that same visit extract: title, company, company size, city, work mode, employment type, posted age, JD language and explicit language-requirement level, technical keywords, poster type, business, `easyApply`, `applyType`, cover-letter hint, top-applicant marker.
3. Never reopen a JD for a missing report field — write `Not stated` / `unknown` / `review` instead.
4. Reuse the single working tab from step 1: navigate it to each canonical URL. Do not open a second tab, not even for a fallback URL or a re-check — the merged list in `job-audit.md` is the search record, so the search page does not need to stay open. An apply-form tab (external ATS) is the only allowed second tab and is closed immediately after its row is written; a `fill`-mode tab the user must submit stays open and is reported. Close the working tab when the last row is written.

Strictly sequential: one posting, one tab, one row at a time.

## 2. Checks, in order — stop at the first confirmed mismatch

0. **Validity** — 404, redirect, or "no longer accepting applications" → expired/closed, skip.
1. **Job title** — strict. The page title (not the card) must contain one entry of `common.jobTitles.include` as a whole phrase, after lowercasing and stripping gender markers and punctuation. Translate a non-English title first — this is a title gate, not a language gate:
   - `Entwickler`/`Entwicklerin`/`Entwicklung` → `Developer`; `Ingenieur` → `Engineer`; `Softwareentwickler` → `Software Engineer`; `Frontend-Entwickler` → `Frontend Developer`; `Webentwickler` → `Web Developer`; `Fullstack-Entwickler` → `Fullstack Developer`; `Anwendungsentwickler` → `Application Developer`.
   - `Developer` = `Engineer`; `TS` → `TypeScript`, `JS` → `JavaScript`, `Dev` → `Developer`, `Sr.` → `Senior`, `Jr.` → `Junior`.
   - A title containing any `jobTitles.excludeWords` word is a confirmed mismatch even when a configured title also appears. Never widen the family for "frontend focus" or "fullstack".
2. **Poster type** — `direct`, `third_party` or `unknown`. `third_party` = staffing firm, headhunter, agency portal, "our client", "on behalf of", `im Auftrag`, `für unseren Kunden`, `Arbeitnehmerüberlassung`. A consultancy hiring for its own projects is `direct`. Unclear → `unknown`. With `thirdPartyPostings: exclude`, a confirmed `third_party` stops here as `not_matched`; with `separate` or `include`, continue — poster type is never a bypass.
3. **JD language** — in `common.jdLanguages.include`. A German JD is **not judged here** when `germanJdPass.enabled` is `true`: record it in `<run>/german-jd-audit.md` (`references/german-jd-pass.md`) and mark the row `deferred (German JD)`. It is not a Part 1 match, not an exclusion and never enters `report.md`; the separate both-lan pass reopens it after this report is published. When `germanJdPass.enabled` is `false`, a German JD is `not_matched` (`JD language: German`) exactly as before. Mixed, short or truncated → `unknown` → review.
4. **Language requirement level** — only when `maxRequiredLevel` has an entry for that language. Map to CEFR: A1 < A2 < B1 < B2 < C1 < C2. `basic`/`Grundkenntnisse` → A2; `good`/`gute`/`solid` → B1; `business fluent` → B2; `fluent`/`fließend`/`verhandlungssicher` → C1; `native`/`muttersprachlich` → C2. Bare `German required` / `Deutschkenntnisse` = B1. `nice to have`, `plus`, `von Vorteil`, `optional` are not requirements. Use the highest stated level. Above the configured level → `not_matched` with `language requirement: <language> <required> > <configured>`; at or below → passes; unmappable → `unknown` → review.
5. **Technical keywords** — per `technicalKeywords.matchMode`; accept JS/JavaScript, TS/TypeScript, NodeJS/Node.js, ReactJS/React. With `any`, stop at the first hit.
6. **Work mode** — only when `workModes` is a real subset. Missing → `unknown`.
7. **Employment type** — only when `employmentTypes` is a real subset. Missing → `unknown`.
8. **Seniority** — only when `seniority.include` is a real subset. Use title or explicit level, never bare years.
9. **Company business** — informational. One short phrase only when the JD states the product, market or industry; otherwise `Not stated`. Never infer it.

Disabled checks are skipped. Confirmed mismatch → `not_matched`, stop. Any `unknown` with no mismatch → `review`. Otherwise `matched`.

**Primary-stack gate.** Before accepting a technical-keyword hit, check the JD's primary stack. If the role's main language/framework is in `common.jobTitles.stackExclude` and `applications.screening.techYears` for it is `0`, classify `not_matched` with reason `primary stack: <stack>`. A secondary mention of React/TypeScript does not override a Java/Python primary stack. Examples:

- A Java/Spring Boot backend role that mentions React in the product description → `not_matched` (`primary stack: Java/Spring Boot`).
- A Python backend role that asks for "some React" → `not_matched` (`primary stack: Python`).
- A React/TypeScript role that mentions Python for a small internal tool → keep, because the primary stack is frontend/TypeScript.

**Third-party gate.** Only a `third_party` posting matched on every active dimension enters the agency/third-party section. A confirmed mismatch goes to Excluded with that reason; an `unknown` goes to review. Never assume full-time, English JD, work mode or seniority from the poster type.

## 3. Save matched postings

Active only when `common.saveMatchedJobs` is `true`. Skipped entirely when it is `false` or absent.

1. Immediately after a vacancy is classified `matched` — normal or confirmed agency/third-party — and **before** touching any Apply control, click that page's Save/bookmark control once.
2. Save is unconditional: it does not depend on `applications.enabled`, on the apply form being fillable, on the form being submitted, or on the user ever applying. `review`, `excluded`, expired and skipped rows are never saved. A save controlled from the search-result card is never used.
3. One click per vacancy. If the page already shows the saved state (`Saved` / `Gespeichert`, a filled bookmark icon), do not click — record `already saved`; never toggle an existing save off.
4. Verify after the click: the control must read `Saved` (localized `Gespeichert`, `收藏` etc.). Only then record `saved`. If the click left the page unchanged, record `not saved: control did not respond`.
5. Save only in the logged-in session you are already using. A login wall, account prompt or missing Save control is recorded as `not saved: login required` / `not saved: no save control` and the run continues — it is not a stop-all signal. Never create an account to save.
6. Where the Save control sits is platform-specific: see `linkedin.md` §9 and `indeed.md` §10.

## 4. Apply control

Record `easyApply` (`yes` / `no` / `unknown`), `applyType` (`easy_apply` / `external` / `unknown`) and `coverLetter` (`yes` / `no` / `unknown`) for every inspected vacancy. They never affect classification.

- `deferred (German JD)` — read the Apply control label only. Never click it, never open a one-click modal, never inspect the employer form, no `fields.json` in Part 1. Record `easyApply` from the label and `applyType: unknown`; the both-lan pass opens the real form later.
- `easy_apply` — open the one-click form once, read-only, record every visible field (label, type, required, options, mapped value) into `<run>/<Company>-<JobTitle>/fields.json`, close it. **Never type, upload or submit.** The row stays with the user.
- `external` — click Apply once, confirm the destination leaves the platform, and inspect the employer form read-only: ATS, host, final `applyUrl`, blockers and every field into `fields.json`. `job-apply` files it after the report; a blocker is written by `job-apply` as `blocked: <reason>` in `fields.json` plus one entry in `.opencode/skills/job-apply/help.json` (`status: "open"`).
- `unknown` — do not click; record it and leave the row for the user.

The daily report carries only the short `Apply form` status, never a field table.

## 5. Cover letters

Draft a cover letter for **every matched vacancy** — Easy Apply, external and every agency/third-party row — whenever `common.isNeededCover` is `true`, whether or not the form exposes a field. Deferred German-JD rows get no letter in Part 1; the both-lan pass drafts one for each row it actually applies to.

- Generation is unconditional; only the upload follows `applications.coverLetterMode`.
- The letter is always written in **English**, whatever `common.preferredReportLanguage` says.
- A `Message to the Hiring Team` textarea counts as a cover-letter field: save a shortened 3–5 sentence version as `<run>/<Company>-<JobTitle>/message.md` and put the text in the report; no PDF.
- For a real upload use the `cover-letter` skill and template exactly — fill only placeholders, never invent, leave unfillable placeholders unchanged and tell the user.
- Save the JSON plus `<First>_<Last>_Cover_Letter.pdf` and record the path. Never upload or submit it.
- If the template is missing, stop that step and tell the user to copy `cover-letter-template-example.md`.

## 6. Output

- `matched` and `review` rows go to the report tables; `not_matched` goes to the excluded table; `deferred (German JD)` rows go only to `<run>/german-jd-audit.md` and carry that status in the main `job-audit.md` merged list (the next run's dedupe needs it). Every row that was inspected is recorded in this run's report and audit only.
- Record `posterType` for every inspected vacancy; record `business` only from an explicit JD statement. For `third_party`, the client goes in Notes.
- Record the `saved` state (`saved` / `already saved` / `not saved: <reason>`) for every matched row in the report's `Saved` column; review and excluded rows are never saved.
- Read the top-applicant marker only when the platform reference defines it and the config enables it (LinkedIn: `platforms.LinkedIn.premium`). It orders rows and is never a check.
- Never score fit, never filter on years, salary, visa, industry, architecture or company size. Record only page facts.

Report structure and columns: `daily-report-format.md`.
