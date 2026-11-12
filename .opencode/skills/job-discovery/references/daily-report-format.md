# Daily report format

This document is the **single format baseline** for every report under `reports/daily/`. The `job-discovery` skill must read it before creating or updating any daily report. If this document conflicts with the skill body or another note, this document wins on structure; the skill still wins on matching logic.

## File location and updates

- One file per local calendar day: `reports/daily/YYYY-MM-DD.md`
- Create the directory if it does not exist
- When today's file already exists, **keep existing content** and only append new findings or new evidence; never overwrite, delete or silently downgrade an entry that was already confirmed
- Deduplication key: the job's canonical URL (within a platform and across platforms); when no canonical URL exists, fall back to `source + company + title + location` and flag a possible duplicate

Cross-day memory, application records and the run audit live in `reports/job-index.json` and `reports/runs/YYYY-MM-DD.jsonl`; their rules are in `job-index-and-audit.md`. They are not part of the daily report and are never pushed to `reportRepo`.

## Language and presentation

- Write all human-readable text in `preferredReportLanguage` from `job-hunter.config.json`. Default to **English** when the field is absent, empty or unsupported, and say so in the final summary.
- Translate the human-readable layer only: title, section headings, table headers, labels (e.g. `Not specified`, `All Germany`, `Exception note`), relative times (e.g. `2 days ago`) and annotation markers (e.g. `[reported MM-DD]`, `[applied MM-DD]`, `⚠️ possible duplicate`, `⚠️ possibly applied MM-DD`).
- Do not translate company names, job titles, technical terms, posted keywords, URLs, dates in `YYYY-MM-DD` or `MM-DD`, index/audit field names, or the priority prompt (`You'd be a top applicant`) and marker `Top applicant`.
- The structure is fixed regardless of language: the same section order, table columns, column order and counts.
- Use **tables** as the main presentation so the report is scannable
- Do not restate long JD passages; do not paste full JDs
- Do not add match scores, rankings, recommendation levels or star ratings, and do not evaluate the candidate profile. The only ordering exception is the platform's own prompt (section 2); never compute one

## Section order

The body starts at the title line and goes straight into tables; no metadata table and no search-scope table:

```markdown
# Daily Job Findings — YYYY-MM-DD
```

The title is part of the human-readable layer: translate `Daily Job Findings` into `preferredReportLanguage` and keep the ` — YYYY-MM-DD` suffix unchanged. The section names below are written in English for reference and are translated the same way.

1. Run summary
2. Matched jobs
3. Needs manual review — **only when there are entries**
4. Excluded jobs — **always the last job table**, after matched and review
5. Exception note — **only when the run failed or was largely unusable**, at the very end

A normal run has only sections 1, 2 and 4; sections 3 and 5 appear conditionally and must never be written as an empty "None". Excluded jobs always come last among the job tables so the actionable rows stay on top.

After that, append "Evidence and consistency rules" and "Cross-day repeats and updates", in that fixed order.

### 1. Run summary

```markdown
| Metric | Value |
|---|---|
| Search sources | LinkedIn (list the platforms actually searched per `sources`) |
| Result pages opened | N |
| Cards skipped before opening | N |
| Expired / closed (skipped) | N |
| Already applied (skipped) | N |
| Job detail pages opened | N |
| JDs read successfully | N |
| Matched | N |
| Needs manual review | N |
| Confirmed non-match (excluded) | N |
| Of which cross-day repeats | N |
```

- Only fill numbers the browser session can support; write `cannot determine` when unknown, and **never estimate**
- Search-result card count ≠ opened job pages; never mix them
- "Cards skipped before opening" counts only cards whose title clearly names a different role family, or that are clearly outside the configured country/location, and that were therefore not opened. They never appear in the excluded table
- "Expired / closed" counts only links that turned out to be 404, redirected away from the job, or explicitly stopped accepting applications. They never appear in the excluded table
- Self-check: matched + review + excluded = pages with a successfully read JD
- "Already applied" and "Expired / closed" both stay out of that sum: the first is decided by the index, the second by the page

### 2. Matched jobs

Group by **city** (`### Munich (13/30)`, `### Berlin (13/30)`, `### Hamburg (4/30)` …), and order each city by **company size**, never by a computed match quality. Matched vacancies that carry the platform's priority prompt go into one leading group first (see below).

- When `locations` is configured, use the configured city names as headings.
- When `locations` is missing or empty (nationwide run), the city comes from each job page; group by the cities actually found. When a page shows only a country (e.g. `Germany`) or is nationwide remote, use `### All Germany` or `### All Germany (Remote)`. Never invent a city to fit an old heading.

The number in parentheses after a city heading is that city's **share of matches**: `matches in this city / total matches today`. The denominator counts only rows in today's matched table, excluding excluded and review rows. Cities without matches do not appear here.

#### Priority group: `You'd be a top applicant`

Matched jobs with the verified prompt (currently LinkedIn Premium, `linkedinPremium: true`) form one group at the top of section 2, before all city groups:

```markdown
### You'd be a top applicant (3/30)
```

- Use the fixed heading `You'd be a top applicant` in every language; the number is `rows with the prompt / total matches today`.
- Same columns; sort by `sortBy` / `sortDirection` inside the group.
- City is not a column: start each Notes cell with the city, e.g. `Berlin; English JD; Full-time`. The row still counts in its city's share heading.
- Omit the group when empty. The prompt never creates a match; a failed job goes to the excluded table instead.

Ordering rules:

- Follow `sortBy` (currently only `companySize`) and `sortDirection` (`asc` / `desc`, default `asc`)
- Company size uses the range shown on the page and compares the **lower bound**: `11-50` → 11, `10001+` → 10001, `9,000` → 9000
- Rows with the same size keep discovery order
- When `sortBy` is missing or unknown, keep discovery order
- After sorting, renumber the `#` column sequentially in the final display order across the priority group and all city groups, and update any internal references (e.g. "same JD as #22")

Fixed columns:

```markdown
| # | Source | Company | Size | Title | Mode | Posted | Matched keywords | Easy Apply | Cover letter | Notes | Link |
|---|---|---|---|---|---|---|---|---|---|---|---|
```

Column rules:

| Column | Rule |
|---|---|
| # | Sequential in final display order, across the priority group and after city grouping and sorting |
| Source | Platform name from `sources`, e.g. `LinkedIn`, `Indeed`; add the domain when the name alone is ambiguous |
| Company | The company field on the job page; when the poster ≠ the actual employer, put the poster here and the employer in Notes |
| Size | The company size shown on the page, e.g. `51-200`, `9,000`, `10001+`; write `Not specified` when absent |
| Title | Keep as published, including (m/f/d), (all genders) and similar suffixes; never put a pipe `|` inside a title, use `·` instead |
| Mode | `On-site` / `Hybrid` / `Remote` as shown; when the page has no such field write `Not specified` and move the row to the review table; add ⚠️ and explain in Notes when it conflicts with the JD body |
| Posted | Relative time (`2 days ago`, `19 hours ago`); mark reposts as `(reposted)` |
| Matched keywords | Only **configured** terms that actually appear in the JD, comma-separated; never add unconfigured technologies |
| Easy Apply | `Yes` when the page shows a one-click apply button on the platform (e.g. LinkedIn "Easy Apply", Indeed "Indeed Apply"), `No` when the apply path clearly leaves the platform or requires an external form, `Unknown` when it cannot be determined |
| Cover letter | `Yes` when the page or application form explicitly says a cover letter is required, `No` when it explicitly says cover letter is optional or not needed, `Unknown` when neither is stated. When `Yes` and `isNeededCover` is `true` in config, a cover letter is drafted from `cover-letter-template.md` and saved under `reports/cover-letters/<company-slug>/<jobId>.md` |
| Notes | Only facts verifiable on the page: main stack, level, contract arrangement, poster/employer mismatch, field conflicts; ≤ about 60 characters; no "great fit" or "recommended" language. Markers follow "Cross-day repeats and updates". Start Notes with the city in the priority group; elsewhere a prompted row adds `Top applicant` |
| Link | `[Open](URL)`, pointing to the canonical job URL actually visited in this run |

City is not a table column: it comes from the section heading (`### Munich (13/30)`), or from the start of Notes inside the priority group. Location details that disagree with the heading (e.g. a role in Pullach, or a remote scope limited to EMEA) go into Notes.

Employment type is a filter, not a column; when it matters for judgment (contract work, parental-leave cover, part-time) write it in Notes.

JD language is also a filter, not a column: matched jobs already satisfy `jdLanguages.include`. When the language cannot be determined and the job goes to the review table, Notes must say "language unknown" and why.

When a job matched because of "German JD + JD explicitly names English as the working language", Notes must state that evidence (e.g. "German JD, names English as team language"); never infer it from the company's international profile.

### 3. Needs manual review

**Only when there are entries**. When empty, omit the whole section; never write "None".

Use the same table structure as section 2, and state in **Notes**:

- which check is unknown (title / language / keywords / work mode / employment type)
- the concrete reason it is missing or ambiguous (JD did not load, too short, truncated, mixed language, page does not expose the field, …)

Prompted rows come first in discovery order and start Notes with `Top applicant`; the prompt never makes an unknown check a match.

Unknown items **must not** be written as matched or excluded.

### 4. Excluded jobs

**Always the last job table**, written after matched and review. A separate section, not counted in the main table. Fixed columns:

```markdown
| # | Source | Company | Title | City | Mode | Posted | Easy Apply | Cover letter | Exclusion reason | Link |
|---|---|---|---|---|---|---|---|---|---|---|
```

- Posted: relative time (`2 days ago`, `19 hours ago`), mark reposts as `(reposted)`; write `Not specified` when the page does not show it
- City: the location shown on the job page; write `Not specified` when absent, never infer
- Exclusion reason must name the **dimension** (JD language / job title / technical keywords / work mode / employment type / seniority (when enabled) / poster type (staffing agency)) plus one short piece of evidence (e.g. the German original fragment, the missing keyword, the mode or type shown on the page, the industry, or an "our client" phrase in the JD)
- Group similar reasons together (e.g. all German JDs) so the table is scannable
- Do not paste long JD passages
- Duplicate relationships (same role in different cities, bilingual copies) may be noted, but must never be double-counted as matches
- A prompted job that failed a check is listed here with only the failed dimension; the prompt is never an exclusion reason
- Jobs skipped at the card stage (clearly wrong title or out of scope) and never opened **do not appear here**; they count only in "Cards skipped before opening"
- **The link column is mandatory**, format `[Open](URL)`, pointing to the job page actually opened in this run, so every row can be checked
- Excluded-table URLs are for manual checking only and **must never be used as a cross-day dedup key** (see "Cross-day repeats and updates")

### 5. Exception note

**Only when one of these happens, and always at the very end**; a normal run never includes it, and routine search parameters (city radius, paging method, time zone) are never listed:

- the run failed or stopped: expired login, CAPTCHA, rate limit, no browser tool
- the run did not finish: result pages left unread, stopped early
- widespread failure: a large share of jobs could not be judged because JDs were unreadable, truncated or missing key fields

Length limit: 3 lines, covering only three things — what happened, how many rows it affected, where it stopped. No disclaimer-style essay.

## Evidence and consistency rules

- Use only facts visible on the job page or verified in the browser session
- Every active matching dimension must be independent and traceable to concrete evidence
- Mark a job as matched only when every active dimension is confirmed
- Write `Not specified` for missing fields; never infer location, work mode, employment type or posting date
- Keep URLs exactly as found; never assemble or invent one
- A job appears at most once in the same report; a match and an exclusion never both count
- The priority prompt is personal Premium UI text: ordering metadata only, never a matching dimension or an inferred signal
- Every daily report uses the same section order and table columns so reports stay comparable
- Do not output candidate-fit, salary-expectation or visa judgments

## Cross-day repeats and updates

A daily report is a **snapshot of that day**, not a cumulative list. Cross-day repeats are still listed; they are only annotated, never removed.

Comparison baseline: prefer `reports/job-index.json`, which covers all history; when the index is missing, fall back to the previous 7 local dates under `reports/daily/`. Only jobs that ever entered the **matched table** or the **review table** count as already reported; excluded and expired entries do not.

| Situation | Handling |
|---|---|
| `firstReportedOn` is set in the index | List the job in today's report as usual and append `[reported MM-DD]` (from `firstReportedOn`) to Notes; never delete it, reclassify it or move it to the excluded table |
| `appliedOn` is set in the index | Do not open or judge it; count it under "Already applied (skipped)" only; it must not appear in any job table |
| Previously appeared only in the excluded table | Not part of dedup; re-evaluate it today |
| No index and no earlier reports | Skip this step and add no marker |

- Markers affect readability only and never reduce the number of jobs actually opened today
- The same URL still appears at most once in today's report
- "Of which cross-day repeats" = rows in today's matched table carrying `[reported …]`
- Always use `MM-DD` in historical markers to avoid cross-year ambiguity

### Same role, different ID

The same job may exist on one platform under several job IDs, in multi-city versions or in bilingual versions; the same job may also appear on several platforms. Compare `normalized company + normalized title + city`; when it is a match and the job ID differs, write `⚠️ possible duplicate` in Notes, or `⚠️ possibly applied MM-DD` when the other posting was applied to. Annotate only — never merge, delete or change counts. Normalization rules are in `job-index-and-audit.md`.

### Application marker

After the user confirms an application, append `[applied MM-DD]` to that job's Notes and write `appliedOn` in the index. The marker does not change today's matched/review decision or any count.

### Cover letter generation

Read `isNeededCover` from `job-hunter.config.json` (default `false`). When `true` and a matched or review job has `coverLetter: "Yes"`, draft a cover letter from the root template `cover-letter-template.md` and save it locally under:

`reports/cover-letters/<company-slug>/<jobId>.md`

- Fill in every bracketed placeholder using facts from the JD page (company, title, job URL, source, matched keywords, JD requirements).
- Never fabricate experience, achievements, or motivations.
- Do not submit automatically — the draft is for manual review and sending.
- Skip jobs where `coverLetter` is `No` or `Unknown`. When `isNeededCover` is `false`, do not draft cover letters even if a JD requires one.

## Updating an existing report

- Keep existing entries and their evidence
- Add or correct only when there is new evidence
- Never silently rewrite an old conclusion because the configuration changed; when new configuration flips a decision, state the reason in the new entry or in Notes
