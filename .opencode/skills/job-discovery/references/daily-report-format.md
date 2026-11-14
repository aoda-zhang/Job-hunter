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
3. Feed-sourced jobs — only with matching feed hiring posts
4. Needs manual review — only with entries
5. Excluded jobs — always last job table
6. Exception note — only on failure

A normal run has sections 1, 2 and 5. Never write an empty section or "None".

Apply the evidence rules (section 9) and cross-day rules (section 10) to the report.

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
- `Feed-sourced jobs` are post-only matches; they are not in the JD sum.
- `Already applied` and `Expired / closed` are outside the JD sum.

## 4. Matched jobs

Group by city: `### Munich (13/30)`. Use configured city names when `locations` is set. For a nationwide run, use the city on each page; use `### All Germany` or `### All Germany (Remote)` when no city is shown. Never invent a city.

The number is `city matches / total matched rows today`. Cities without matches do not appear.

Priority group: matched jobs with the verified `You'd be a top applicant` prompt go first:

```markdown
### You'd be a top applicant (3/30)
```

- Keep the heading text in every language. Number = prompted rows / total matches.
- Start Notes with the city; the row still counts in its city share.
- Omit the group when empty. The prompt never creates a match.

Ordering:

- Follow `sortBy` (currently `companySize`) and `sortDirection` (`asc` default).
- Compare the lower bound: `11-50` → 11, `10001+` → 10001, `9,000` → 9000.
- Ties keep discovery order. Unknown `sortBy` keeps discovery order.
- Renumber `#` across the priority group and all city groups; update internal references.

Columns:

```markdown
| # | Source | Company | Size | Title | Mode | Posted | Matched keywords | Easy Apply | Cover letter | Notes | Link |
|---|---|---|---|---|---|---|---|---|---|---|---|
```

| Column | Rule |
|---|---|
| # | Sequential in final display order |
| Source | Platform name from `sources`; add the domain when ambiguous |
| Company | Company on the page; if poster ≠ employer, put the poster here and the employer in Notes |
| Size | Range shown on the page, e.g. `51-200`, `9,000`, `10001+`; `Not specified` when absent |
| Title | As published, including `(m/f/d)` and `(all genders)`; replace `|` with `·` |
| Mode | `On-site` / `Hybrid` / `Remote`; `Not specified` + review when absent; add ⚠️ when it conflicts with the JD |
| Posted | Relative time; mark reposts `(reposted)` |
| Matched keywords | Only configured terms actually in the JD, comma-separated |
| Easy Apply | `Yes` for a one-click platform apply, `No` for an external form, `Unknown` otherwise |
| Cover letter | `Yes` / `No` / `Unknown` from the page or form; draft only when `Yes` and `isNeededCover` is `true` |
| Notes | Verifiable facts only: stack, level, contract, poster/employer mismatch, conflicts; ≤ about 60 characters; no fit language |
| Link | `[Open](canonical URL)` actually visited in this run |

City is not a column. Put location conflicts in Notes. Employment type and JD language are filters, not columns; put relevant evidence in Notes. For a German JD with English as the working language, state that evidence; never infer it.

## 5. Feed-sourced jobs

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

## 6. Needs manual review

Only with entries. Use the matched table. In Notes, name the unknown check (title / language / keywords / work mode / employment type) and the concrete reason (JD did not load, too short, truncated, mixed language, field not exposed). Prompted rows first, starting Notes with `Top applicant`. An unknown check never becomes a match or an exclusion.

## 7. Excluded jobs

Always the last job table.

```markdown
| # | Source | Company | Title | City | Mode | Posted | Easy Apply | Cover letter | Exclusion reason | Link |
|---|---|---|---|---|---|---|---|---|---|---|
```

- `City`: page location; `Not specified` when absent.
- `Posted`: relative time; `(reposted)`; `Not specified` when absent.
- `Exclusion reason`: name the dimension (JD language / title / keywords / work mode / employment type / seniority / poster type) plus one short evidence fragment.
- Group similar reasons. Do not paste long JD passages.
- Duplicate relationships may be noted; never double-count.
- A prompted job that failed a check lists only the failed dimension.
- Cards skipped before opening never appear here.
- `Link` is mandatory: `[Open](URL)` for the page opened in this run.
- Never use excluded URLs as a cross-day dedup key.

## 8. Exception note

Only on a failed, interrupted or largely unusable run; always at the end. Cover what happened, how many rows it affected, and where it stopped. Maximum 3 lines. Never list routine parameters.

## 9. Evidence and consistency

- Use only facts visible on the page or verified in the browser.
- Mark `matched` only when every active dimension is confirmed.
- Write `Not specified` for missing fields; never infer location, mode, type or date.
- Keep URLs exactly as found; never assemble one.
- One job appears at most once in a report; a match and an exclusion never both count.
- Feed jobs use post text only; never open external links to verify.
- Feed jobs match on role + location only; other dimensions never exclude.
- A non-matching feed hiring post appears nowhere, including the excluded table.
- A feed job appears only in the feed section; do not duplicate a matched or review row.
- The priority prompt is ordering metadata only.
- Never output candidate-fit, salary or visa judgments.

## 10. Cross-day repeats

A report is a daily snapshot. List repeats and annotate them; never remove them.

Use `job-index.json`; if missing, use the previous 7 daily reports. Only jobs that entered a matched or review table count as reported; excluded and expired do not.

| Situation | Handling |
|---|---|
| `firstReportedOn` set | List normally; append `[reported MM-DD]` to Notes; never delete or reclassify |
| `appliedOn` set | Do not open or judge; count as applied-skipped; never list |
| Excluded only before | Not a repeat; re-evaluate today |
| No index or reports | Skip and add no marker |

- Markers never reduce today's opened count.
- The same URL appears once.
- `Of which cross-day repeats` = matched rows with `[reported …]`.
- Use `MM-DD` to avoid cross-year ambiguity.

Soft duplicates: same normalized company + title + city with a different ID → `⚠️ possible duplicate`, or `⚠️ possibly applied MM-DD` when applied. Annotate only; never merge or change counts. Normalization rules are in `job-index-and-audit.md`.

Application marker: after the user confirms, append `[applied MM-DD]` to Notes and set `appliedOn`. Do not change the decision or counts.

Cover letter: draft only when `isNeededCover` is `true` and `coverLetter` is `Yes`, for a matched or review job. Copy `cover-letter-template.md` exactly; fill only its placeholders from the page; leave unfillable placeholders unchanged and tell the user. Save to `reports/cover-letters/<company-slug>/<jobId>.md`. Never fabricate. Do not submit. If the template is missing, stop and tell the user to copy `cover-letter-template-example.md`.

## 11. Update an existing report

Keep existing entries and evidence. Preserve `Feed-sourced jobs` and its rows. Add or correct only with new evidence. Never silently rewrite an old conclusion; state the reason when new config changes a decision.
