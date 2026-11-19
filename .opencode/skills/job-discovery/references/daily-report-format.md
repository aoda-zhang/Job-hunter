# Daily report format

Format baseline for `reports/daily/`. Read before writing or updating a report. This file wins on structure; the skill wins on matching logic.

## 1. File and language

- One file per local date: `reports/daily/YYYY-MM-DD.md`.
- Create the directory when missing.
- Merge into an existing file; never overwrite, delete or downgrade a confirmed entry.
- Deduplicate by canonical URL; without one, use `source + company + title + location` and flag a possible duplicate.
- Keep `job-index.json` and `runs/` out of the report and out of `reportRepo`.

Write human-readable text in `preferredReportLanguage`; fall back to English when absent or unsupported.

Translate: title, headings, table headers, labels, relative times, annotation markers.

Do not translate: company names, job titles, technical terms, URLs, `YYYY-MM-DD` / `MM-DD`, field names, `You'd be a top applicant`.

Use tables. Do not paste full JDs. Do not add scores, rankings, recommendations or candidate-fit judgments.

## 2. Section order

```markdown
# Daily Job Findings — YYYY-MM-DD
```

Translate `Daily Job Findings`; keep ` — YYYY-MM-DD`.

1. Run summary
2. Matched jobs
3. `代招岗位` (third-party postings) — only with confirmed third-party postings that passed every other check
4. Feed-sourced jobs — only with matching feed hiring posts
5. Needs manual review — only with entries
6. Excluded jobs — always last job table
7. Exception note — only on failure

A normal run has sections 1, 2 and 6. Never write an empty section or "None".

Apply the evidence rules (section 10) and cross-day rules (section 11) to the report.

## 3. Run summary

```markdown
| Metric | Value |
|---|---|
| Search sources | LinkedIn |
| Result pages opened | N |
| Cards skipped before opening | N |
| Expired / closed (skipped) | N |
| Already applied (skipped) | N |
| Job detail pages opened | N |
| JDs read successfully | N |
| Matched | N |
| Of which Easy Apply | N |
| Of which No Easy Apply (external) | N |
| Of which third-party postings (`代招岗位`) | N |
| External applications filled (awaiting submit) | N |
| External applications submitted | N |
| Feed-sourced jobs | N |
| Needs manual review | N |
| Confirmed non-match (excluded) | N |
| Of which cross-day repeats | N |
```

- Write `cannot determine` when unsupported; never estimate.
- Do not mix result cards with opened pages.
- `Cards skipped before opening`: clearly wrong role family or outside `countries`/`locations`. Never in the excluded table.
- `Expired / closed`: 404, redirect away, or no longer accepting. Never in the excluded table.
- Check: matched + review + excluded = pages with a successfully read JD.
- `Matched` includes confirmed third-party postings listed in `代招岗位`; the third-party row is a subset, not an extra count.
- `Of which Easy Apply` and `Of which No Easy Apply` add up to `Matched`; they are a workflow split, not extra matches.
- `Feed-sourced jobs` are post-only matches; they are not in the JD sum.
- `Already applied` and `Expired / closed` are outside the JD sum.

## 4. Matched jobs

Do not group rows by city. Put the page location in the `City` column. Confirmed third-party postings go to section 5, not this table.

Split the matched jobs into exactly two parts, in this order. The split is a workflow split, not a filter: it never creates, removes or reclassifies a match.

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
- These are the external third-party applications. `job-apply` fills the form and leaves the tab open; the user clicks the final Submit.
- An `Unknown` row is allowed here only with `external redirect not verified` in Notes.
- Keep the heading text `No Easy Apply` in every language.
- Number = rows in this part / total rows in this section.

Ordering:

- Easy Apply part first, then No Easy Apply part.
- Within the Easy Apply part, put prompted rows first.
- Within the No Easy Apply part, put prompted rows first and prefix their Notes with `Top applicant`.
- Within each part, follow `sortBy` (currently `companySize`) and `sortDirection` (`asc` default).
- Compare the lower bound: `11-50` → 11, `10001+` → 10001, `9,000` → 9000.
- Ties keep discovery order. Unknown `sortBy` keeps discovery order.
- Renumber `#` across both parts; update internal references.
- Each part is a separate table with the same header row; `#` stays continuous across parts.
- Omit a part only when it has zero rows.

Columns:

```markdown
| # | Source | Company | Size | Business | Title | City | Mode | Posted | Matched keywords | Easy Apply | Cover letter | Notes | Link |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
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
| Cover letter | `Yes` / `No` / `Unknown` from the page or form; draft only when `Yes` and `isNeededCover` is `true` |
| Notes | Verifiable facts only: stack, level, contract, poster/employer mismatch, conflicts; ≤ about 60 characters; no fit language |
| Link | `[Open](canonical URL)` actually visited in this run |

Put location conflicts in Notes. Employment type and JD language are filters, not columns; put relevant evidence in Notes. For a German JD with English as the working language, state that evidence; never infer it.

## 5. 代招岗位 (third-party postings)

Only with at least one confirmed third-party posting that passed every other active check. Never write an empty section.

- Heading: `代招岗位` in a Chinese report; `Agency / third-party postings` in other report languages.
- Same columns, evidence rules, keyword matching, two-part split (Easy Apply, then No Easy Apply) and ordering as Matched jobs. Number `#` from 1 inside this section; both heading denominators use this section's total.
- `thirdPartyPostings` decides placement: `separate` = this section, `include` = normal matched rows, `exclude` = excluded table.
- Confirm the poster is a staffing firm, headhunter, agency or platform posting for a client. "Clearly" means the JD states the relation; unclear goes to review.
- `Company`: the posting company (the agency or platform). Notes start with `代招：<client>` or `代招（客户未注明）` (`Third party: <client>` / `Third party: client not stated`), then one verifiable fact.
- `Business`: the client employer's product, market or industry when the JD states it; `Not stated` otherwise.
- A third-party posting that fails title, JD language, keywords, work mode, employment type or seniority goes to Excluded with that reason, never here.
- These rows count as matched in the summary, cross-day repeats and possible-duplicate checks.

## 6. Feed-sourced jobs

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

## 7. Needs manual review

Only with entries. Use the matched table. In Notes, name the unknown check (title / language / keywords / work mode / employment type) and the concrete reason (JD did not load, too short, truncated, mixed language, field not exposed). Order rows as in Matched jobs (Easy Apply first, then No Easy Apply) without adding the two part headings; start prompted rows' Notes with `Top applicant`. An unknown check never becomes a match or an exclusion.

## 8. Excluded jobs

Always the last job table.

```markdown
| # | Source | Company | Title | City | Mode | Posted | Easy Apply | Cover letter | Exclusion reason | Link |
|---|---|---|---|---|---|---|---|---|---|---|
```

- `City`: page location; `Not specified` when absent.
- `Posted`: relative time; `(reposted)`; `Not specified` when absent.
- `Exclusion reason`: name the dimension (JD language / title / keywords / work mode / employment type / seniority / poster type) plus one short evidence fragment.
- `poster type` is a valid reason only when `thirdPartyPostings` is `exclude`; in `separate` or `include` mode a third-party posting is judged on the other dimensions.
- Group similar reasons. Do not paste long JD passages.
- Duplicate relationships may be noted; never double-count.
- A prompted job that failed a check lists only the failed dimension.
- Cards skipped before opening never appear here.
- `Link` is mandatory: `[Open](URL)` for the page opened in this run.
- Never use excluded URLs as a cross-day dedup key.

## 9. Exception note

Only on a failed, interrupted or largely unusable run; always at the end. Cover what happened, how many rows it affected, and where it stopped. Maximum 3 lines. Never list routine parameters.

## 10. Evidence and consistency

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

## 11. Cross-day repeats

A report is a daily snapshot. List repeats and annotate them; never remove them.

Use `job-index.json`; if missing, use the previous 7 daily reports. Only jobs that entered a matched, `代招岗位` or review table count as reported; excluded and expired do not.

| Situation | Handling |
|---|---|
| `firstReportedOn` set | List normally; append `[reported MM-DD]` to Notes; never delete or reclassify |
| `appliedOn` set | Do not open or judge; count as applied-skipped; never list |
| Excluded only before | Not a repeat; re-evaluate today |
| No index or reports | Skip and add no marker |

- Markers never reduce today's opened count.
- The same URL appears once.
- `Of which cross-day repeats` = matched rows with `[reported …]`, including `代招岗位` rows.
- Use `MM-DD` to avoid cross-year ambiguity.

Soft duplicates: same normalized company + title + city with a different ID → `⚠️ possible duplicate`, or `⚠️ possibly applied MM-DD` when applied. Annotate only; never merge or change counts. Normalization rules are in `job-index-and-audit.md`.

Application marker: after the user confirms, append `[applied MM-DD]` to Notes and set `appliedOn`. Do not change the decision or counts.

Application staging markers (written by `job-apply` only):

- `[filled MM-DD]` — form complete and waiting for the user's Submit; `applyStatus: "filled"`, `appliedOn` still `null`.
- `[applied MM-DD]` — submit confirmed on the page; set `appliedOn`.
- `[apply blocked MM-DD]` — a blocker stopped the attempt; name it briefly.
- Easy Apply rows never get these markers from the agent; the user applies and confirms them.

Cover letter: draft only when `isNeededCover` is `true` and `coverLetter` is `Yes`, for a matched or review job. Copy `cover-letter-template.md` exactly; fill only its placeholders from the page; leave unfillable placeholders unchanged and tell the user. Save to `reports/cover-letters/<company-slug>/<jobId>.md`. Never fabricate. Do not submit. If the template is missing, stop and tell the user to copy `cover-letter-template-example.md`.

## 12. Update an existing report

Keep existing entries and evidence. Preserve `代招岗位` and `Feed-sourced jobs` sections and their rows. Add or correct only with new evidence. Never silently rewrite an old conclusion; state the reason when new config changes a decision.

When a config change reclassifies a job (for example a previously excluded third-party posting now passes and belongs in `代招岗位`), move the row to the correct table, keep its evidence and counts consistent, and state the reason in Notes. Never leave the same job in two tables.
