# Daily report format

Format baseline for `reports/daily/`. Read before writing or updating a report. This file wins on structure; the skill wins on matching logic.

## 1. File and language

- One file per local date: `reports/daily/YYYY-MM-DD.md`.
- Create the directory when missing.
- Merge into an existing file; never overwrite, delete or downgrade a confirmed entry.
- Deduplicate by canonical URL; without one, use `source + company + title + location` and flag a possible duplicate.
- Keep `job-index.json` and `runs/` out of the report and out of `common.reportRepo`.

Write human-readable text in `common.preferredReportLanguage`; fall back to English when absent or unsupported.

Translate: title, headings, table headers, labels, relative times, annotation markers.

Do not translate: company names, job titles, technical terms, URLs, `YYYY-MM-DD` / `MM-DD`, field names, `You'd be a top applicant`.

Use tables. Do not paste full JDs. Do not add scores, rankings, recommendations or candidate-fit judgments.

## 2. Section order

```markdown
# Daily Job Findings — YYYY-MM-DD
```

Translate `Daily Job Findings`; keep ` — YYYY-MM-DD`.

1. Run summary
2. Matched jobs — one section per source, in `sources` order (LinkedIn first, then Indeed)
3. `代招岗位` (third-party postings) — only with confirmed third-party postings that passed every other check
4. Apply-form fields — only for an inspected external apply form that was not submitted successfully
5. Feed-sourced jobs — only with matching feed hiring posts
6. Needs manual review — only with entries
7. Excluded jobs — always last job table
8. Exception note — only on failure

A normal run has sections 1, 2 and 6. Never write an empty section or "None".

When `common.report.splitBySource` is `false`, section 2 is a single matched section with the same two parts; everything else is unchanged.

Apply the evidence rules (section 11) and cross-day rules (section 12) to the report.

## 3. Run summary

Keep it short: one row group per metric, one column per source plus a total. Everything else goes to the audit JSONL.

```markdown
| Metric | LinkedIn | Indeed | Total |
|---|---|---|---|
| Search queries | 1 | 5 | — |
| JDs read | N | N | N |
| Previously reported (skipped) | N | N | N |
| Applied on another platform (skipped) | N | N | N |
| Matched | N | N | N |
| Of which Easy Apply / No Easy Apply | N / N | N / N | N / N |
| Of which third-party postings (`代招岗位`) | N | N | N |
| Confirmed non-match (excluded) | N | N | N |
| Needs manual review | N | N | N |
| Apply forms inspected | N | N | N |
| Feed-sourced jobs | N | — | N |
```

- Use the source names from `sources`, in order. When a source was disabled or failed, write `—` in its cells and name the reason in the audit/limitations.
- Write `cannot determine` when unsupported; never estimate.
- Check per source and in total: matched + review + excluded = JDs read.
- `Matched` includes confirmed third-party postings listed in `代招岗位`; the third-party row is a subset, not an extra count.
- `Of which Easy Apply / No Easy Apply` adds up to `Matched`; it is a workflow split, not extra matches.
- `Previously reported (skipped)`, `Applied on another platform (skipped)` and `Feed-sourced jobs` are outside the JD sum.
- `Already applied` and `Expired / closed` are outside the JD sum.
- When `job-apply` ran after the report was written, add `External applications filled (awaiting submit)` and `External applications submitted` rows with the same per-source columns. They are outside the JD sum.

## 4. Matched jobs

Do not group rows by city. Put the page location in the `City` column. Confirmed third-party postings go to section 5, not this table.

### 4.1 Source sections

When `common.report.splitBySource` is `true` (default):

```markdown
## LinkedIn 职位
## Indeed 职位
```

- One section per source that has at least one matched row, in `sources` order (LinkedIn first, then Indeed).
- Translate the heading in `common.preferredReportLanguage`; keep the platform name as configured.
- `#` restarts at 1 in every source section; the per-source row total drives that section's part denominators.
- Do not write an empty source section.
- With `splitBySource: false`, write a single `## Matched jobs` section and number continuously.

### 4.2 Workflow split inside a source

Split the section's matched jobs into exactly two parts, in this order. The split is a workflow split, not a filter: it never creates, removes or reclassifies a match.

```markdown
### Easy Apply (5/30)
```

- All matched jobs with `Easy Apply = Yes`, including prompted rows.
- Keep the heading text `Easy Apply` in every language, or its localized equivalent of the column header.
- The user applies to these manually. The agent never opens, fills or submits them.
- Number = rows in this part / total rows in this section.

```markdown
### No Easy Apply (25/30)
```

- Every other matched job: `Easy Apply = No`, plus `Unknown`.
- These are the external applications. The apply form is inspected and its fields are recorded; the user decides whether to file.
- An `Unknown` row is allowed here only with `external redirect not verified` in Notes.
- Keep the heading text `No Easy Apply` in every language.
- Number = rows in this part / total rows in this section.

Ordering:

- Easy Apply part first, then No Easy Apply part, inside every source section.
- Within the Easy Apply part, put prompted rows first.
- Within the No Easy Apply part, put prompted rows first and prefix their Notes with `Top applicant`.
- Within each part, follow `common.sortBy` (currently `companySize`) and `common.sortDirection` (`asc` default).
- Compare the lower bound: `11-50` → 11, `10001+` → 10001, `9,000` → 9000.
- Ties keep discovery order. Unknown `common.sortBy` keeps discovery order.
- Renumber `#` across both parts inside the source section; update internal references.
- Each part is a separate table with the same header row; `#` stays continuous across parts of the same source.
- Omit a part only when it has zero rows.
- Do not sort across sources: `sources` order always wins.

Columns:

```markdown
| # | Source | Company | Size | Business | Title | City | Mode | Posted | Matched keywords | Easy Apply | Cover letter | Notes | Apply form | Link |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
```

| Column | Rule |
|---|---|
| # | Sequential in final display order |
| Source | Platform name from `sources`; add the domain when ambiguous |
| Company | Company on the page; if poster ≠ employer, put the poster here and the employer in Notes |
| Size | Range shown on the page, e.g. `51-200`, `9,000`, `10001+`; `Not specified` when absent |
| Business (`公司业务` in a Chinese report) | One short phrase, only when the JD explicitly states the company's product, market or industry, e.g. `B2B logistics SaaS`; `Not stated` when absent; never infer from the company name, domain or another page; ≤ about 40 characters |
| Title | As published, including `(m/f/d)` and `(all genders)`; replace `|` with `·` |
| City | Page location as published; `Not specified` when absent; keep multiple cities in the page's order separated by ` · `; never infer or normalize to a configured city |
| Mode | `On-site` / `Hybrid` / `Remote`; `Not specified` + review when absent; add ⚠️ when it conflicts with the JD |
| Posted | Relative time; mark reposts `(reposted)` |
| Matched keywords | Only configured terms actually in the JD, comma-separated |
| Easy Apply | `Yes` for a one-click platform apply, `No` for an external form, `Unknown` otherwise; ordering only, never a filter |
| Cover letter | `Yes` / `No` / `Unknown` from the page or form; draft when the form shows the field and `common.isNeededCover` is `true` |
| Notes | Verifiable facts only: stack, level, contract, poster/employer mismatch, conflicts; ≤ about 60 characters; no fit language |
| Apply form | `Inspected (N fields)` linking to the job's block in section 6; `Blocked — <reason>` when the form is login-walled; empty for Easy Apply |
| Link | `[Open](canonical URL)` actually visited in this run |

Put location conflicts in Notes. Employment type and JD language are filters, not columns; put relevant evidence in Notes. For a German JD with English as the working language, state that evidence; never infer it.

## 5. 代招岗位 (third-party postings)

Only with at least one confirmed third-party posting that passed every active check. Never write an empty section.

- Heading: `代招岗位` in a Chinese report; `Agency / third-party postings` in other report languages.
- Same columns, evidence rules, keyword matching, two-part split (Easy Apply, then No Easy Apply) and ordering as Matched jobs. Number `#` from 1 inside this section; both heading denominators use this section's total.
- Rows from different sources keep `sources` order; the two-part split still comes first.
- `common.thirdPartyPostings` decides placement: `separate` = this section, `include` = normal matched rows, `exclude` = excluded table.
- Confirm the poster is a staffing firm, headhunter, agency or platform posting for a client. "Clearly" means the JD states the relation; unclear goes to review.
- `Company`: the posting company (the agency or platform). Notes start with `代招：<client>` or `代招（客户未注明）` (`Third party: <client>` / `Third party: client not stated`), then one verifiable fact.
- `Business`: the client employer's product, market or industry when the JD states it; `Not stated` otherwise.
- Gate: a third-party posting must match every active filter exactly like a direct posting. A confirmed mismatch in title, JD language, language requirement level, keywords, work mode, employment type or seniority goes to Excluded with that reason, never here. An `unknown` on any active filter goes to Needs manual review, never here.
- Never infer full-time, English JD, on-site/hybrid or a seniority level from the poster type; read it from the posting.
- These rows count as matched in the summary, cross-day repeats and possible-duplicate checks.

## 6. Apply-form fields

Only with at least one inspected external apply form **that was not successfully submitted**. A vacancy whose application was submitted successfully (`applyStatus: "submitted"` / `appliedOn` set) gets **no** block here: its record lives only in `reports/applications/YYYY-MM-DD.md`. In the matched table its `Apply form` cell reads `已提交` (`Submitted`). Keep blocks for every block that is not submitted yet: `blocked`, `filled` (waiting for the user's Submit), `failed`, and inspected-only rows.

One block per non-submitted matched `No Easy Apply` vacancy, in the same order as the matched tables and numbered to match them (`<source> #<n>` when the report is split by source).

```markdown
### 3. Zalando — Software Engineer (Kotlin) - Transport Planning Optimization
ATS: Zalando Careers · Link: https://jobs.zalando.com/... · Login: No · Cover letter: Optional
Draft: reports/cover-letters/zalando/4465977883.md

| # | Field | Type | Required | Value to fill |
|---|---|---|---|---|
| 1 | First Name | text | Yes | Qi |
| 2 | Last Name | text | Yes | Zhang |
| 3 | Email | email | Yes | zhangqi20031994@gmail.com |
| 4 | Phone | tel | Yes | +86 191 0263 2826 |
| 5 | Salary expectations | number | Yes | 70000 |
| 6 | Background check | radio | Yes | needs confirmation (legal declaration) |
```

- `Value to fill` is the exact config/CV value. When the config lacks it, write `needs confirmation (<config key>)`; never invent.
- Legal declarations (background check, sanctions, criminal record, disability, veteran status) are always `needs confirmation`.
- Privacy, data-processing, talent-pool, contact and interview-recording consents are always `同意`.
- A `Message to the Hiring Team` / `Message to the team` box counts as a cover-letter field: write the shortened 3–5 sentence text in the value cell and save it as `reports/cover-letters/<slug>/<jobId>-message.md`; no PDF.
- `Login: Yes` means the form was blocked: omit the field table and write `Blocker: <reason>` instead.
- `Cover letter` is `Required` / `Optional` / `Not shown` / `Message box`. When the field exists, write the saved draft path and export a PDF only for a real upload.
- Never paste a full JD or free text here; only field labels, types, requirements and mapped values.

## 7. Feed-sourced jobs

Only with at least one matching feed hiring post. Never write an empty section. `job-discovery` must preserve this section.

- Only confirmed matches; non-matching hiring posts appear nowhere.
- Following status is irrelevant.
- Role and location are mandatory; conflicting stack, mode, employment type, seniority or language goes in Notes, never a drop.
- Never infer company, role or location.

```markdown
| # | Source | Company | Title | Location | Mode | Posted | Matched keywords | Notes | Link |
|---|---|---|---|---|---|---|---|---|---|
| 1 | LinkedIn Feed | Example GmbH | Senior Frontend Engineer | Berlin | Hybrid | 2h ago | React, TypeScript | 来自 feed; hiring manager post | [Open](URL) |
```

- `Source`: `LinkedIn Feed`.
- `Matched keywords`: configured terms named; `None matched` when a stack is named but no term matches; `Not stated` when no stack.
- `Notes`: start with `来自 feed` (`From feed` for non-Chinese), then one verifiable fact.
- `Link`: copied permalink or `Link unavailable`.
- Deduplicate against matched, review and existing feed rows. One job = one section.
- Renumber `#` after merging.

## 8. Needs manual review

Only with entries. Use the matched table. In Notes, name the unknown check (title / language / keywords / work mode / employment type) and the concrete reason (JD did not load, too short, truncated, mixed language, field not exposed). Group rows by source in `sources` order, then order them as in Matched jobs (Easy Apply first, then No Easy Apply) without adding the part headings; start prompted rows' Notes with `Top applicant`. An unknown check never becomes a match or an exclusion.

## 9. Excluded jobs

Always the last job table.

```markdown
| # | Source | Company | Title | City | Mode | Posted | Easy Apply | Cover letter | Exclusion reason | Link |
|---|---|---|---|---|---|---|---|---|---|---|
```

- `City`: page location; `Not specified` when absent.
- `Posted`: relative time; `(reposted)`; `Not specified` when absent.
- `Exclusion reason`: name the dimension (JD language / language requirement / title / keywords / work mode / employment type / seniority / poster type) plus one short evidence fragment.
- `poster type` is a valid reason only when `common.thirdPartyPostings` is `exclude`; in `separate` or `include` mode a third-party posting is judged on the other dimensions.
- Group similar reasons. Do not paste long JD passages.
- Duplicate relationships may be noted; never double-count.
- A prompted job that failed a check lists only the failed dimension.
- Cards skipped before opening never appear here.
- `Link` is mandatory: `[Open](URL)` for the page opened in this run.
- Never use excluded URLs as a cross-day dedup key.

## 10. Exception note

Only on a failed, interrupted or largely unusable run; always at the end. Cover what happened, how many rows it affected, and where it stopped. Maximum 3 lines. Never list routine parameters.

## 11. Evidence and consistency

- Use only facts visible on the page or verified in the browser.
- Mark `matched` only when every active dimension is confirmed. `matched` includes confirmed third-party rows listed in `代招岗位`.
- A confirmed third-party posting appears once: in `代招岗位` when every other check passes, otherwise in the excluded table. Never both.
- Write `Not specified` for missing fields; never infer location, mode, type, date or company business.
- Keep URLs exactly as found; never assemble one.
- One job appears at most once in a report; a match and an exclusion never both count.
- Feed jobs use post text only; never open external links to verify.
- Feed jobs match on role + location only; other dimensions never exclude.
- A non-matching feed hiring post appears nowhere, including the excluded table.
- A feed job appears only in the feed section; do not duplicate a matched or review row.
- The priority prompt and Easy Apply are ordering metadata only; neither ever creates or removes a job.
- Never output candidate-fit, salary or visa judgments.

## 12. Previous report dedupe

A report is a daily snapshot. At run start, the previous daily report is the skip source: every job ID / canonical URL in its tables is skipped before opening and appears nowhere in today's report. This prevents overlap from the daily `common.lookbackHours` window. `job-index.json` is not the source for this skip; it only supplies the applied set for the cross-source rule.

| Situation | Handling |
|---|---|
| Key in the previous daily report | Do not open, judge or list; count as previously reported (skipped) |
| `appliedOn` set | Do not open or judge; count as applied-skipped; never list |
| Applied on another platform (normalized company + title + city) and `common.dedupe.skipApplied` is `true` | Do not open or judge; count as applied on another platform (skipped); never list, never apply again |
| Same vacancy on two platforms, not applied (and `common.dedupe.crossSource` is `true`) | Keep the first source's row; annotate the second `⚠️ 同职位已在 <source> 出现` when it still appears |
| Explicit re-check override | Exempt the named keys for that run; list normally and append `[reported MM-DD]` |
| No previous report | Check every card |

- Markers never reduce today's opened count.
- The same URL appears once.
- `Of which cross-day repeats` = matched rows with `[reported …]`, including `代招岗位` rows. With the default previous-report skip it is normally 0.
- Use `MM-DD` to avoid cross-year ambiguity.

Soft duplicates: same normalized company + title + city with a different ID → `⚠️ possible duplicate`, or `⚠️ possibly applied MM-DD` when applied. Annotate only; never merge or change counts. Normalization rules are in `job-index-and-audit.md`.

Application marker: after the user confirms, append `[applied MM-DD]` to Notes and set `appliedOn`. Do not change the decision or counts.

Application staging markers (written by `job-apply` only):

- `[filled MM-DD]` — form complete and waiting for the user's Submit; `applyStatus: "filled"`, `appliedOn` still `null`.
- `[applied MM-DD]` — submit confirmed on the page; set `appliedOn`.
- `[apply blocked MM-DD]` — a blocker stopped the attempt; name it briefly.
- Easy Apply rows never get these markers from the agent; the user applies and confirms them.

Cover letter: draft only when `common.isNeededCover` is `true` and `coverLetter` is `Yes`, for a matched or review job. Copy `cover-letter-template.md` exactly; fill only its placeholders from the page; leave unfillable placeholders unchanged and tell the user. Save to `reports/cover-letters/<company-slug>/<jobId>.md`. Never fabricate. Do not submit. If the template is missing, stop and tell the user to copy `cover-letter-template-example.md`.

## 13. Update an existing report

Keep existing entries and evidence. Preserve `代招岗位` and `Feed-sourced jobs` sections and their rows. Add or correct only with new evidence. Never silently rewrite an old conclusion; state the reason when new config changes a decision.

When a config change reclassifies a job (for example a previously excluded third-party posting now passes and belongs in `代招岗位`), move the row to the correct table, keep its evidence and counts consistent, and state the reason in Notes. Never leave the same job in two tables.
