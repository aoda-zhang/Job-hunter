# Daily report format

Format baseline for `reports/daily/`. Read before writing or updating a report. This file wins on structure; the skill wins on matching logic.

## 1. File and language

- **One folder per run**: `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/`, containing `report.md` plus one folder per appliable vacancy (`<Company>-<JobTitle>/`). `HHMM` is the run's local start time (24h, `Asia/Shanghai` unless configured otherwise). A run starting 21:01 writes `reports/daily/2026-11-20/2026-11-20-2101/report.md`.
- Every appliable matched vacancy gets `<run>/<Company>-<JobTitle>/` with:

```text
<run>/<Company>-<JobTitle>/fields.json                       # every form field, required and optional
<run>/<Company>-<JobTitle>/cover-letter.json                 # template fields for this vacancy
<run>/<Company>-<JobTitle>/<First>_<Last>_Cover_Letter.pdf  # the rendered letter
```

```json
{
  "first_name": "Qi",
  "last_name": "Zhang",
  "email": "zhangqi20031994@gmail.com",
  "phone": "+86 191 0263 2826",
  "city": "Chengdu, China",
  "salary_expectation": "",
  "note": "apply DONE"
}
```

- The file is a flat object: one key per field the application requires, value = the answer to fill. Key = the form label in `snake_case`, value = the configured answer, or `""` when the answer is unknown, unconfigured or unanswered (never `null`, never invented).
- `note` is the only non-field key: `apply DONE` when this run submitted the application automatically, otherwise `blocked: <concrete blocker>` or `not applied: <reason>`.
- No job metadata inside the file (`jobId`, `company`, `ats`, `applyUrl`, …): the folder name identifies the vacancy, the report row carries the link and status.
- Easy Apply: open the apply modal read-only once, record the fields it shows, close it — **never submit and never fill it**.
- Folder name = company + published job title, spaces → hyphens, umlauts transliterated (`ä`→`ae`, `ö`→`oe`, `ü`→`ue`, `ß`→`ss`) and gender markers dropped: `AboutYou-Senior-TypeScript-Developer`, `Wolt-Senior-Software-Engineer`. Never use ids or dates in the name.
- The folder exists for every matched row that has an apply control: Easy Apply rows get their read-only field map, external rows get theirs plus the fill/blocker note. Third-party rows are included only when `common.thirdPartyPostings` is not `exclude`.
- `report.md` never contains field tables; its `Apply form` cell carries only the short status.
- Two runs that start in the same minute: append `-2`, `-3`, … (`2026-11-20-2101-2/`). Never merge them.
- A second run on the same day gets its own new folder. **Never merge across runs, never append today's results to an earlier run's folder, and never rewrite an earlier run's report.**
- The same run keeps one folder: a later step of that run (`job-apply`) edits the files the run created, not "today's report". Feed hiring posts are written only by the separate feed pass, never by `job-discovery`.
- Create the directories when missing.
- Deduplicate inside a run's report by canonical URL; without one, use `source + company + title + location` and flag a possible duplicate.
- Keep `runs/` and `reports/applications/` out of the report and out of `common.reportRepo`. Run folders (report plus per-job `fields.json`, `cover-letter.json` and the PDF) are published.

Write human-readable text in `common.preferredReportLanguage`; fall back to English when absent or unsupported.

**This applies to the report only.** Nothing in this file changes what an employer receives: every application field, free-text answer, cover letter and uploaded document is written in **English only**, whatever the report language is.

Translate: title, headings, table headers, labels, relative times, annotation markers.

Do not translate: company names, job titles, technical terms, URLs, `YYYY-MM-DD` / `MM-DD`, field names, `You'd be a top applicant`.

Use tables. Do not paste full JDs. Do not add scores, rankings, recommendations or candidate-fit judgments.

## 2. Section order

```markdown
# Daily Job Findings — YYYY-MM-DD HH:MM
```

Translate `Daily Job Findings`; keep ` — YYYY-MM-DD HH:MM` (the run's start time, minute precision).

0. Run header (mandatory): run id, start time, end time, sources processed in this run, scope, apply-dedupe result
1. Run summary
2. Matched jobs — one section per source, in `sources` order (LinkedIn first, then Indeed)
4. `Agency / third-party postings` — only with confirmed third-party postings that passed every other check
5. Feed-sourced jobs — only with matching feed hiring posts
6. `Submitted` — only when at least one application was submitted
7. Exception note — only on failure

`report.md` lists **only vacancies worth applying to** (matched and submitted). Review and excluded jobs are not tables in the report: every merged card, its final status and the exact reason live in `job-audit.md`.

A normal run has the run header, the summary and the matched sections. Never write an empty section or "None". The step-1 record **and every exclusion reason** live in `job-audit.md` next to the report.

Apply-form field tables never go in the report. They are written per vacancy to `<run>/<Company>-<JobTitle>/fields.json`; the report's `Apply form` cell carries only the short status.

### 2.1 Run header

Write it as a plain list directly under the title, before the summary:

```markdown
- Run id: `2026-11-20-2101`
- Start: 2026-11-20 21:01 (Asia/Shanghai)
- End: 2026-11-20 21:51
- Sources this run: LinkedIn (Indeed not run in this pass)
- Scope: all of Germany (no city limit)
- Search titles (in order): <common.searchTitles, separated by ·>
- Platform filters (verified): Past 24 hours · Full-time
- Apply dedupe: previous run `job-audit.md` merged list and today's `reports/applications/` checked before the run; N already-applied hits; none re-applied
- Saved: N matched jobs saved on the platform (LinkedIn N · Indeed N); M not saved
- Report: `reports/daily/2026-11-20/2026-11-20-2101/report.md`
```

- `Saved` is written only when `common.saveMatchedJobs` is `true`; name each not-saved reason in the audit, not in the header.

- `Start` = the moment the run started searching; `End` = the moment report, index and audit were finished. Both in local time with minutes; keep the timezone label on the start line only.
- Take both values from the same clock source; never write a planned or estimated end time.
- `Apply dedupe` must state the real result of the pre-run check. When it skipped jobs, name the count and keep the skipped rows out of every table.

When `common.report.splitBySource` is `false`, section 3 is a single matched section with the same parts; everything else is unchanged.

Apply the evidence rules (section 10) and cross-day rules (section 11) to the report.

### 2.2 job-audit is a separate file

Mandatory in every run, but written to `<run>/job-audit.md`, never into `report.md`. The report header links to it (one line). It is the evidence that step 1 saw the whole result set; it is **not** a match list and never carries JD-derived fields.

**Per-title table** — one row per configured search title, in config order:

```markdown
| Search title | Results | Pages | Cards | New after dedupe |
|---|---|---|---|---|
| JavaScript Developer | 100 | 4 | 100 | 100 |
| Full-Stack Developer | 224 | 9 | 224 | 128 |
```

- `Results`: the count the platform displayed, verbatim (e.g. `99+ results`); write `not shown` when absent.
- `New after dedupe`: cards from this title that no earlier title in the run had already returned.

**Merged list** — one row per unique vacancy from step 1, after merging titles and sources:

```markdown
| # | Company | Title | Link | Search titles | Status / reason |
|---|---|---|---|---|---|
| 1 | go-e | Frontend Engineer (m/f/x) | [Open](https://www.linkedin.com/jobs/view/4492956185/) | JavaScript Developer | sent to JD review |
| 2 | ABOUT YOU | Senior Frontend Engineer (all genders) | [Open](https://www.linkedin.com/jobs/view/4492575758/) | JavaScript Developer · Full-Stack Developer | sent to JD review |
| 3 | adesso SE | Trainee SAP Software Developer (all genders) | [Open](https://www.linkedin.com/jobs/view/4467504321/) | JavaScript Developer | removed by shallow filter |
```

- `Status / reason` is the final state after step 3, written in the report language, e.g. `标题不符合`, `第二层过滤：sap`, `早期严格匹配：标题不含配置职位`, `JD 为德语`, `JD 要求德语 B2 > 配置 A2`, `技术栈不符`, `匹配（Easy Apply）`, `匹配（外部投递）`, `需复核：工作模式未标注`, `上次已记录（跳过）`. Every row of the merged list gets exactly one final status.
- `Search titles`: every search title that returned this vacancy, separated by ` · `.
- `Link`: canonical URL, always `[Open](url)`.
- `removed by shallow filter` requires an obviously wrong title (other function, or a `jobTitles.excludeWords` word). `Software Engineer`, `Developer`, `Engineer` and anything ambiguous **must** be `sent to JD review`.
- Sort the merged list by company, then title; `#` restarts at 1.
- A vacancy that reaches the matched/review/excluded tables appears here too — this table is the audit trail, not a duplicate of the results.

**Counts line** directly under the title tables:

```markdown
This run: 2 search titles · 324 cards · 228 unique · 18 removed by shallow filter · 210 sent to JD review
```

Translate headings and status values into `common.preferredReportLanguage`; keep company, title and URL unchanged.

## 3. Run summary

Per run, never a day total. Counts come only from this run's rows.

Keep it short: one row group per metric, one column per source plus a total. Everything else goes to the audit JSONL.

```markdown
| Metric | LinkedIn | Indeed | Total |
|---|---|---|---|
| Search titles | 2 | 2 | — |
| Result cards collected | N | N | N |
| Unique after merge | N | N | N |
| Removed by shallow title filter | N | N | N |
| Sent to JD review | N | N | N |
| JDs read | N | N | N |
| Previously reported (skipped) | N | N | N |
| Applied on another platform (skipped) | N | N | N |
| Matched | N | N | N |
| Of which Easy Apply / No Easy Apply | N / N | N / N | N / N |
| Saved on the platform (matched rows) | N | N | N |
| Needs manual review | N | N | N |
| Feed-sourced jobs | N | — | N |
```

- Use the source names from `sources`, in order. When a source was disabled or failed, write `—` in its cells and name the reason in the audit/limitations.
- The `检查 JD` / funnel rows must match the counts in `job-audit.md` exactly.
- Write `cannot determine` when unsupported; never estimate.
- The audit JSONL keeps the full counts (excluded, third-party postings, inspected forms); the summary table shows only the rows above.
- `Matched` includes confirmed third-party postings listed in `Agency / third-party postings`.
- `Of which Easy Apply / No Easy Apply` adds up to `Matched`; it is a workflow split, not extra matches.
- `Saved on the platform` counts matched rows saved or already saved this run; write `—` when `common.saveMatchedJobs` is not `true`.
- `Previously reported (skipped)`, `Applied on another platform (skipped)` and `Feed-sourced jobs` are outside the JD sum.
- When `job-apply` filled or submitted forms, add an `External applications filled / submitted / blocked` row. It is outside the JD sum.

## 4. Matched jobs

Do not group rows by city. Put the page location in the `City` column. Confirmed third-party postings go to section 4, not this table.

### 4.1 Source sections

When `common.report.splitBySource` is `true` (default):

```markdown
## LinkedIn jobs
## Indeed jobs
```

- One section per source that has at least one matched row, in `sources` order (LinkedIn first, then Indeed).
- Translate the heading in `common.preferredReportLanguage`; keep the platform name as configured.
- `#` restarts at 1 in every source section; the per-source row total drives that section's part denominators.
- Do not write an empty source section.
- With `splitBySource: false`, write a single `## Matched jobs` section and number continuously.

### 4.2 Workflow split inside a source

Split the section's matched jobs into exactly two parts, in this order. The split is a workflow split, not a filter: it never creates, removes or reclassifies a match. Submitted rows are not part of this split; they live in the global `Submitted` section (4.3).

```markdown
### Easy Apply (5/12)
```

- All matched jobs with `Easy Apply = Yes` that are not submitted, including top-applicant rows.
- Keep the heading text `Easy Apply` in every language, or its localized equivalent of the column header.
- The agent opens each one-click form once, read-only, and records its fields in `fields.json`. It never fills or submits — the user applies manually.
- Number = rows in this part / total non-submitted rows in this section.

```markdown
### No Easy Apply (7/12)
```

- Every other matched job that is not submitted: `Easy Apply = No`, plus `Unknown`.
- These are the external applications. The form is inspected, recorded in `fields.json`, and filed by `job-apply` (fill/submit per `applications.externalApply`); when it cannot be filed, the blocker goes to `help.json`.
- An `Unknown` row is allowed here only with `external redirect not verified` in Notes.
- Keep the heading text `No Easy Apply` in every language.
- Number = rows in this part / total non-submitted rows in this section.

Ordering:

- Easy Apply part first, then No Easy Apply part, inside every source section.
- Within each part, put top-applicant rows first.
- Within the No Easy Apply part, prefix top-applicant rows' Notes with `Top applicant`.
- Within each part, follow `common.sortBy` (currently `companySize`) and `common.sortDirection` (`asc` default).
- Compare the lower bound: `11-50` → 11, `10001+` → 10001, `9,000` → 9000.
- Ties keep discovery order. Unknown `common.sortBy` keeps discovery order.
- Renumber `#` across both parts inside the source section; update internal references.
- Each part is a separate table with the same header row; `#` stays continuous across parts of the same source.
- Omit a part only when it has zero rows.
- Do not sort across sources: `sources` order always wins.

Columns:

```markdown
| # | Company | Notes | Apply form | Saved | Link | Size | Business | Title | City | Mode | Posted | Matched keywords | Easy Apply | Cover letter | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
```

| Column | Rule |
|---|---|
| # | Sequential in final display order |
| Company | Company on the page; if poster ≠ employer, put the poster here and the employer in Notes |
| Notes | Verifiable facts only: stack, level, contract, poster/employer mismatch, conflicts; ≤ about 90 characters; no fit language. Every external row (`Easy Apply` = `No` / `Unknown`) that was not submitted ends with `Not auto-submitted: <reason>` (translated in the report language), naming the concrete cause: login or account creation, a required field the config cannot answer, rejected value, CAPTCHA, expired posting, browser/relay failure, or a policy skip |
| Apply form | `Inspected` (fields in the vacancy folder's `fields.json`), `Blocked`, `Submitted`, or `Not external` for a one-click apply recorded read-only |
| Saved | `Saved` (verified this run), `Already saved` (untouched), `Not saved: <reason>` (no save control, sign-in wall, control did not respond), or `—` when `common.saveMatchedJobs` is not `true` or the row is not a match |
| Link | `[Open](canonical URL)` actually visited in this run |
| Size | Range shown on the page, e.g. `51-200`, `9,000`, `10001+`; `Not specified` when absent |
| Business (localized heading in other report languages) | One short phrase, only when the JD explicitly states the company's product, market or industry, e.g. `B2B logistics SaaS`; `Not stated` when absent; never infer from the company name, domain or another page; ≤ about 40 characters |
| Title | As published, including `(m/f/d)` and `(all genders)`; replace `|` with `·` |
| City | Page location as published; `Not specified` when absent; keep multiple cities in the page's order separated by ` · `; never infer or normalize to a configured city |
| Mode | `On-site` / `Hybrid` / `Remote`; `Not specified` + review when absent; add ⚠️ when it conflicts with the JD |
| Posted | Relative time; mark reposts `(reposted)` |
| Matched keywords | Only configured terms actually in the JD, comma-separated |
| Easy Apply | `Yes` for a one-click platform apply, `No` for an external form, `Unknown` otherwise; ordering only, never a filter |
| Cover letter | `Yes` / `No` / `Unknown` from the page or form; the letter itself is drafted for every matched row when `common.isNeededCover` is `true`, Easy Apply included |
| Source | Platform name from `sources`; add the domain when ambiguous. Always the last column: the section heading already names the platform |

Put location conflicts in Notes. Employment type and JD language are filters, not columns; put relevant evidence in Notes. For a German JD with English as the working language, state that evidence; never infer it.

### 4.3 `Submitted`

A single top-level section, always immediately before the excluded table (section order 8). Only write it when at least one matched application was submitted.

```markdown
## Submitted

| # | Company | Notes | Apply form | Saved | Link | Size | Business | Title | City | Mode | Posted | Matched keywords | Easy Apply | Cover letter | Source |
```

- Heading: `Submitted` (translated in the report language).
- Only matched rows whose application was submitted (`applyStatus: "submitted"` / `appliedOn` set, `Apply form` = `Submitted`); excluded, review and feed rows never appear here.
- Same columns as Matched jobs. Number `#` from 1 across the whole section.
- Order by `sources` order first (LinkedIn, then Indeed), then `common.sortBy`/`common.sortDirection`; ties keep the order they had in the matched table.
- When an application is submitted, move the row out of its source section into this section and renumber the source section's `#` and part totals.
- These rows still count as matched in the run summary and in cross-day dedupe.

## 5. Agency / third-party postings

Only with at least one confirmed third-party posting that passed every active check. Never write an empty section.

- Heading: `Agency / third-party postings` (translated in the report language).
- Same columns, evidence rules, keyword matching, part split (Easy Apply, then No Easy Apply) and ordering as Matched jobs. A submitted row leaves this section for the global `Submitted` section. Number `#` from 1 inside this section; both heading denominators use this section's non-submitted total.
- Rows from different sources keep `sources` order; the part split still comes first.
- `common.thirdPartyPostings` decides placement: `separate` = this section, `include` = normal matched rows, `exclude` = excluded table.
- Confirm the poster is a staffing firm, headhunter, agency or platform posting for a client. "Clearly" means the JD states the relation; unclear goes to review.
- `Company`: the posting company (the agency or platform). Notes start with `Third party: <client>` or `Third party: client not stated`, then one verifiable fact.
- `Business`: the client employer's product, market or industry when the JD states it; `Not stated` otherwise.
- Gate: a third-party posting must match every active filter exactly like a direct posting. A confirmed mismatch in title, JD language, language requirement level, keywords, work mode, employment type or seniority goes to Excluded with that reason, never here. An `unknown` on any active filter goes to Needs manual review, never here.
- Never infer full-time, English JD, on-site/hybrid or a seniority level from the poster type; read it from the posting.
- These rows count as matched in the summary, cross-day repeats and possible-duplicate checks.

## 6. Feed-sourced jobs

Only with at least one matching feed hiring post. Never write an empty section. `job-discovery` must preserve this section.

- Only confirmed matches; non-matching hiring posts appear nowhere.
- Following status is irrelevant.
- Role and location are mandatory; conflicting stack, mode, employment type, seniority or language goes in Notes, never a drop.
- Never infer company, role or location.

```markdown
| # | Company | Notes | Link | Title | Location | Mode | Posted | Matched keywords | Source |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Example GmbH | From feed; hiring manager post | [Open](URL) | Senior Frontend Engineer | Berlin | Hybrid | 2h ago | React, TypeScript | LinkedIn Feed |
```

- `Source`: `LinkedIn Feed`.
- `Matched keywords`: configured terms named; `None matched` when a stack is named but no term matches; `Not stated` when no stack.
- `Notes`: start with `From feed`, then one verifiable fact.
- `Link`: copied permalink or `Link unavailable`.
- Deduplicate against matched, review and existing feed rows. One job = one section.
- Renumber `#` after merging.

## 7. Needs manual review

Only with entries. Use the matched table. In Notes, name the unknown check (title / language / keywords / work mode / employment type) and the concrete reason (JD did not load, too short, truncated, mixed language, field not exposed). Group rows by source in `sources` order, then order them as in Matched jobs (Easy Apply first, then No Easy Apply) without adding the part headings; start top-applicant rows' Notes with `Top applicant`. An unknown check never becomes a match or an exclusion. Review rows are never saved: the `Saved` cell is `—`.

## 8. Excluded jobs

Always the last job table.

```markdown
| # | Company | Exclusion reason | Link | Title | City | Mode | Posted | Easy Apply | Cover letter | Source |
|---|---|---|---|---|---|---|---|---|---|---|
```

- `City`: page location; translate `Not specified` into the report language.
- `Posted`: relative time, translated into the report language; `(reposted)` translated too; `Not specified` translated when absent.
- `Exclusion reason`: name the dimension (JD language / language requirement / title / keywords / work mode / employment type / seniority / poster type) plus one short evidence fragment. **Write the whole reason in `common.preferredReportLanguage`** — dimension name and evidence prefix included; the quoted JD evidence may stay in its original language.
- `poster type` is a valid reason only when `common.thirdPartyPostings` is `exclude`; in `separate` or `include` mode a third-party posting is judged on the other dimensions.
- Group similar reasons. Do not paste long JD passages.
- Duplicate relationships may be noted; never double-count.
- A top-applicant job that failed a check lists only the failed dimension.
- Cards skipped before opening never appear here.
- `Link` is mandatory: `[Open](URL)` for the page opened in this run.
- Never use excluded URLs as a cross-day dedup key.

## 9. Exception note

Only on a failed, interrupted or largely unusable run; always at the end. Cover what happened, how many rows it affected, and where it stopped. Maximum 3 lines. Never list routine parameters.

## 10. Evidence and consistency

- Use only facts visible on the page or verified in the browser.
- Mark `matched` only when every active dimension is confirmed. `matched` includes confirmed third-party rows listed in `Agency / third-party postings`.
- A confirmed third-party posting appears once: in `Agency / third-party postings` when every other check passes, otherwise in the excluded table. Never both.
- Write `Not specified` for missing fields; never infer location, mode, type, date or company business.
- Keep URLs exactly as found; never assemble one.
- One job appears at most once in a report; a match and an exclusion never both count.
- Feed jobs use post text only; never open external links to verify.
- Feed jobs match on role + location only; other dimensions never exclude.
- A non-matching feed hiring post appears nowhere, including the excluded table.
- A feed job appears only in the feed section; do not duplicate a matched or review row.
- The top-applicant marker and Easy Apply are ordering metadata only; neither ever creates or removes a job.
- A `Saved` state is reported only after it was verified in the browser; never assume a save succeeded.
- Never output candidate-fit, salary or visa judgments.

## 11. Previous-run dedupe

A report is a single run's snapshot. The skip source is the **single most recent earlier run** (same day or previous day, whichever is newer): every job ID / canonical URL in that run's `job-audit.md` **merged list** is skipped before opening — regardless of the status it ended with last time (matched, review, excluded, shallow-filtered or skipped) — and appears nowhere in this run's report. Only when that audit file is missing or has no merged list does the skip source fall back to the previous `report.md` tables; record that fallback in `limitations`.

With `common.dedupe.previousRunOnly` (`true` by default) no older run is read — the 24-hour window cannot reach it. With `common.dedupe.checkAppliedHistory` (`false` by default) the applied history is not scanned; applications from the previous run are covered because that run's audit is the previous-run set.

| Situation | Handling |
|---|---|
| Key in the most recent earlier run's `job-audit.md` merged list | Do not open, judge or list; count as previously reported (skipped) |
| Key only in that run's `report.md` (no audit) | Same handling, after the documented fallback |
| Applied in that earlier run | Already covered by the row above; never listed, never applied again |
| Same vacancy on two platforms, not applied (and `common.dedupe.crossSource` is `true`) | Keep the first source's row; annotate the second `⚠️ same job on <source>` |
| Explicit re-check override | Exempt the named keys; list normally and append `[reported MM-DD HH:MM]` |
| No earlier run | Check every card |

- A previous `review` or `excluded` row is not re-opened: the run that judged it is the authority for the 24-hour window. A config change or a failed page does not retroactively reopen it; only an explicit re-check override does.
- Markers never reduce today's opened count.
- The same URL appears once per run file; a repeated vacancy may appear again in a later run only as `[reported MM-DD HH:MM]` after an explicit override.
- Use `MM-DD HH:MM` in markers so a repeat points at the exact run.

## 12. Update an existing report

Only the current run's own file may be updated, and only by this run's later step (`job-apply`). Feed hiring posts belong to the separate feed pass. Never reopen or edit another run's report, and never merge two runs into one file.

Keep existing entries and evidence inside that file. Preserve `Agency / third-party postings` and `Feed-sourced jobs` sections and their rows. Add or correct only with new evidence. Never silently rewrite an old conclusion; state the reason when new config changes a decision. When the header's `End` or apply-dedupe line becomes outdated, update those two lines.

When a config change reclassifies a job (for example a previously excluded third-party posting now passes and belongs in `Agency / third-party postings`), move the row to the correct table, keep its evidence and counts consistent, and state the reason in Notes. Never leave the same job in two tables.
