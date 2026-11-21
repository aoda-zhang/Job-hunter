# Daily report format

Format baseline for `reports/daily/`. Read before writing or updating a report. This file wins on structure; the skill wins on matching logic.

## 1. File and language

- **One folder per run**: `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/`, containing `report.md` plus one folder per appliable vacancy (`<jobId>/`). `HHMM` is the run's local start time (24h, `Asia/Shanghai` unless configured otherwise). A run starting 21:01 writes `reports/daily/2026-11-20/2026-11-20-2101/report.md`.
- Every appliable matched vacancy gets `<run>/<jobId>/` with:

```text
<run>/<jobId>/fields.json                       # every form field, required and optional
<run>/<jobId>/cover-letter.json                 # template fields for this vacancy
<run>/<jobId>/Qi_Zhang_<Role>_Cover_Letter.pdf  # the rendered letter
```

```json
{
  "jobId": "linkedin-4484812650",
  "company": "Wolt",
  "title": "Senior Software Engineer (Fullstack) - Merchant EMEA",
  "source": "LinkedIn",
  "status": "inspected | blocked | submitted | not_started",
  "ats": "Greenhouse",
  "applyUrl": "https://job-boards.greenhouse.io/wolt/jobs/8141574",
  "blocker": "",
  "coverLetter": "optional | required | not_shown | unknown",
  "fields": [
    { "label": "First Name", "type": "text", "required": true, "value": "Qi" },
    { "label": "Salary expectation", "type": "text", "required": false, "value": "" }
  ]
}
```

- `fields` lists every visible field, required and optional. When the value is unknown, unconfigured or unread, write `""` — never `null`, never an invented value.
- The folder exists only for jobs that can be applied to: matched, not excluded, and not a one-click-only row. Third-party rows are included only when `common.thirdPartyPostings` is not `exclude`.
- `report.md` never contains field tables; its `Apply form` cell carries only the short status.
- Two runs that start in the same minute: append `-2`, `-3`, … (`2026-11-20-2101-2/`). Never merge them.
- A second run on the same day gets its own new folder. **Never merge across runs, never append today's results to an earlier run's folder, and never rewrite an earlier run's report.**
- The same run keeps one folder: later steps of that run (`job-apply`, `linkedin-feed-jobs`) edit the files the run created, not "today's report".
- Create the directories when missing.
- Deduplicate inside a run's report by canonical URL; without one, use `source + company + title + location` and flag a possible duplicate.
- Keep `job-index.json` and `runs/` out of the report and out of `common.reportRepo`.

Write human-readable text in `common.preferredReportLanguage`; fall back to English when absent or unsupported.

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
3. `代招岗位` (third-party postings) — only with confirmed third-party postings that passed every other check
4. Feed-sourced jobs — only with matching feed hiring posts
5. Needs manual review — only with entries
6. `已提交` (submitted jobs) — only when at least one application was submitted; always immediately before the excluded table
7. Excluded jobs — always last job table
8. Exception note — only on failure

A normal run has sections 0, 1, 2 and 5. Never write an empty section or "None".

Apply-form field tables never go in the report. They are written per vacancy to `<run>/<jobId>/fields.json`; the report's `Apply form` cell carries only the short status.

### 2.1 Run header

Write it as a plain list directly under the title, before the summary:

```markdown
- 运行编号：`2026-11-20-2101`
- 开始时间：2026-11-20 21:01（Asia/Shanghai）
- 结束时间：2026-11-20 21:51
- 本轮来源：LinkedIn（Indeed 未在本轮执行）
- 搜索范围：德国全境（未限定城市）
- 投递查重：运行前已核对 `reports/job-index.json` 与 `reports/applications/`，本轮命中已投递岗位 N 条，未重复投递
- 本轮报告：`reports/daily/2026-11-20/2026-11-20-2101.md`
```

- `开始时间` = the moment the run started searching; `结束时间` = the moment report, index and audit were finished. Both in local time with minutes; keep the timezone label on the start line only.
- Take both values from the same clock source; never write a planned or estimated end time.
- `投递查重` must state the real result of the pre-run check. When it skipped jobs, name the count and keep the skipped rows out of every table.

When `common.report.splitBySource` is `false`, section 2 is a single matched section with the same parts; everything else is unchanged.

Apply the evidence rules (section 10) and cross-day rules (section 11) to the report.

## 3. Run summary

Per run, never a day total. Counts come only from this run's rows.

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
| Needs manual review | N | N | N |
| Feed-sourced jobs | N | — | N |
```

- Use the source names from `sources`, in order. When a source was disabled or failed, write `—` in its cells and name the reason in the audit/limitations.
- Write `cannot determine` when unsupported; never estimate.
- The audit JSONL keeps the full counts (excluded, third-party postings, inspected forms); the summary table shows only the rows above.
- `Matched` includes confirmed third-party postings listed in `代招岗位`.
- `Of which Easy Apply / No Easy Apply` adds up to `Matched`; it is a workflow split, not extra matches.
- `Previously reported (skipped)`, `Applied on another platform (skipped)` and `Feed-sourced jobs` are outside the JD sum.
- When `job-apply` ran after the report was written, add an `External applications submitted` row with the same per-source columns. It is outside the JD sum.

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

Split the section's matched jobs into exactly two parts, in this order. The split is a workflow split, not a filter: it never creates, removes or reclassifies a match. Submitted rows are not part of this split; they live in the global `已提交` section (4.3).

```markdown
### Easy Apply (5/12)
```

- All matched jobs with `Easy Apply = Yes` that are not submitted, including prompted rows.
- Keep the heading text `Easy Apply` in every language, or its localized equivalent of the column header.
- The user applies to these manually. The agent never opens, fills or submits them.
- Number = rows in this part / total non-submitted rows in this section.

```markdown
### No Easy Apply (7/12)
```

- Every other matched job that is not submitted: `Easy Apply = No`, plus `Unknown`.
- These are the external applications. The apply form is inspected and its fields are recorded; the user decides whether to file.
- An `Unknown` row is allowed here only with `external redirect not verified` in Notes.
- Keep the heading text `No Easy Apply` in every language.
- Number = rows in this part / total non-submitted rows in this section.

Ordering:

- Easy Apply part first, then No Easy Apply part, inside every source section.
- Within each part, put prompted rows first.
- Within the No Easy Apply part, prefix prompted rows' Notes with `Top applicant`.
- Within each part, follow `common.sortBy` (currently `companySize`) and `common.sortDirection` (`asc` default).
- Compare the lower bound: `11-50` → 11, `10001+` → 10001, `9,000` → 9000.
- Ties keep discovery order. Unknown `common.sortBy` keeps discovery order.
- Renumber `#` across both parts inside the source section; update internal references.
- Each part is a separate table with the same header row; `#` stays continuous across parts of the same source.
- Omit a part only when it has zero rows.
- Do not sort across sources: `sources` order always wins.

Columns:

```markdown
| # | Company | Notes | Apply form | Link | Size | Business | Title | City | Mode | Posted | Matched keywords | Easy Apply | Cover letter | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
```

| Column | Rule |
|---|---|
| # | Sequential in final display order |
| Company | Company on the page; if poster ≠ employer, put the poster here and the employer in Notes |
| Notes | Verifiable facts only: stack, level, contract, poster/employer mismatch, conflicts; ≤ about 90 characters; no fit language. Every external row (`Easy Apply` = `No` / `Unknown`) that was not submitted ends with `无法自动提交：<reason>` (`Not auto-submitted: <reason>` in other report languages), naming the concrete cause: login or account creation, a required field the config cannot answer, rejected value, CAPTCHA, expired posting, browser/relay failure, or a policy skip |
| Apply form | `Inspected` (details in the vacancy folder's `fields.json`), `Blocked` or `Submitted`; empty for Easy Apply |
| Link | `[Open](canonical URL)` actually visited in this run |
| Size | Range shown on the page, e.g. `51-200`, `9,000`, `10001+`; `Not specified` when absent |
| Business (`公司业务` in a Chinese report) | One short phrase, only when the JD explicitly states the company's product, market or industry, e.g. `B2B logistics SaaS`; `Not stated` when absent; never infer from the company name, domain or another page; ≤ about 40 characters |
| Title | As published, including `(m/f/d)` and `(all genders)`; replace `|` with `·` |
| City | Page location as published; `Not specified` when absent; keep multiple cities in the page's order separated by ` · `; never infer or normalize to a configured city |
| Mode | `On-site` / `Hybrid` / `Remote`; `Not specified` + review when absent; add ⚠️ when it conflicts with the JD |
| Posted | Relative time; mark reposts `(reposted)` |
| Matched keywords | Only configured terms actually in the JD, comma-separated |
| Easy Apply | `Yes` for a one-click platform apply, `No` for an external form, `Unknown` otherwise; ordering only, never a filter |
| Cover letter | `Yes` / `No` / `Unknown` from the page or form; the letter itself is drafted for every matched row when `common.isNeededCover` is `true`, Easy Apply included |
| Source | Platform name from `sources`; add the domain when ambiguous. Always the last column: the section heading already names the platform |

Put location conflicts in Notes. Employment type and JD language are filters, not columns; put relevant evidence in Notes. For a German JD with English as the working language, state that evidence; never infer it.

### 4.3 `已提交` (submitted jobs)

A single top-level section, always immediately before the excluded table (section order 7). Only write it when at least one matched application was submitted.

```markdown
## 已提交

| # | Company | Notes | Apply form | Link | Size | Business | Title | City | Mode | Posted | Matched keywords | Easy Apply | Cover letter | Source |
```

- Heading: `已提交` in a Chinese report, `Submitted` otherwise.
- Only matched rows whose application was submitted (`applyStatus: "submitted"` / `appliedOn` set, `Apply form` = `已提交`); excluded, review and feed rows never appear here.
- Same columns as Matched jobs. Number `#` from 1 across the whole section.
- Order by `sources` order first (LinkedIn, then Indeed), then `common.sortBy`/`common.sortDirection`; ties keep the order they had in the matched table.
- When an application is submitted, move the row out of its source section into this section; renumber the source section's `#` and part totals, drop the row's apply-form block and renumber the remaining blocks.
- These rows still count as matched in the run summary and in cross-day dedupe.

## 5. 代招岗位 (third-party postings)

Only with at least one confirmed third-party posting that passed every active check. Never write an empty section.

- Heading: `代招岗位` in a Chinese report; `Agency / third-party postings` in other report languages.
- Same columns, evidence rules, keyword matching, part split (Easy Apply, then No Easy Apply) and ordering as Matched jobs. A submitted row leaves this section for the global `已提交` section. Number `#` from 1 inside this section; both heading denominators use this section's non-submitted total.
- Rows from different sources keep `sources` order; the part split still comes first.
- `common.thirdPartyPostings` decides placement: `separate` = this section, `include` = normal matched rows, `exclude` = excluded table.
- Confirm the poster is a staffing firm, headhunter, agency or platform posting for a client. "Clearly" means the JD states the relation; unclear goes to review.
- `Company`: the posting company (the agency or platform). Notes start with `代招：<client>` or `代招（客户未注明）` (`Third party: <client>` / `Third party: client not stated`), then one verifiable fact.
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
| 1 | Example GmbH | 来自 feed; hiring manager post | [Open](URL) | Senior Frontend Engineer | Berlin | Hybrid | 2h ago | React, TypeScript | LinkedIn Feed |
```

- `Source`: `LinkedIn Feed`.
- `Matched keywords`: configured terms named; `None matched` when a stack is named but no term matches; `Not stated` when no stack.
- `Notes`: start with `来自 feed` (`From feed` for non-Chinese), then one verifiable fact.
- `Link`: copied permalink or `Link unavailable`.
- Deduplicate against matched, review and existing feed rows. One job = one section.
- Renumber `#` after merging.

## 7. Needs manual review

Only with entries. Use the matched table. In Notes, name the unknown check (title / language / keywords / work mode / employment type) and the concrete reason (JD did not load, too short, truncated, mixed language, field not exposed). Group rows by source in `sources` order, then order them as in Matched jobs (Easy Apply first, then No Easy Apply) without adding the part headings; start prompted rows' Notes with `Top applicant`. An unknown check never becomes a match or an exclusion.

## 8. Excluded jobs

Always the last job table.

```markdown
| # | Company | Exclusion reason | Link | Title | City | Mode | Posted | Easy Apply | Cover letter | Source |
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

## 11. Previous-report dedupe

A report is a single run's snapshot. At run start, the skip source is **every earlier run's report**, plus the latest previous-day runs:

1. all `reports/daily/YYYY-MM-DD/YYYY-MM-DD-*.md` of today whose `HHMM` is earlier than this run's start, and
2. every run report of the most recent previous date (`reports/daily/<prev-date>/*.md`).

Extract every job ID / canonical URL from all their tables into the **previous-report set**; a card in this set is not opened, not judged and not listed.

**Apply preflight (mandatory, before the first platform).** Build the applied set from two local sources and record the result in the report header:

- `reports/job-index.json`: every entry with `appliedOn` set or `applyStatus` in `submitted` / `filled`;
- `reports/applications/*.md`: every `Submitted` / `Filled (awaiting submit)` row of the last 30 days.

Any vacancy in that set is skipped on every platform, never opened, never listed and **never submitted again**, even when the run is a re-check or the posting reappeared with a new ID (match on normalized identity, not only URL). This is what keeps a 20:40 run from repeating the 15:40 run: the second run of the day lists only genuinely new postings and says `0 new` when nothing is left.

| Situation | Handling |
|---|---|
| Key in an earlier run's report of the same day | Do not open, judge or list; count as previously reported (skipped) |
| Key in the previous day's runs | Do not open, judge or list; count as previously reported (skipped) |
| `appliedOn` set | Do not open or judge; count as applied-skipped; never list |
| Applied on another platform (normalized company + title + city) and `common.dedupe.skipApplied` is `true` | Do not open or judge; count as applied on another platform (skipped); never list, never apply again |
| Same vacancy on two platforms, not applied (and `common.dedupe.crossSource` is `true`) | Keep the first source's row; annotate the second `⚠️ 同职位已在 <source> 出现` when it still appears |
| Explicit re-check override | Exempt the named keys for that run; list normally and append `[reported MM-DD HH:MM]` |
| No earlier report | Check every card |

- Markers never reduce today's opened count.
- The same URL appears once per run file; the same vacancy may appear again in a later run only as `[reported MM-DD HH:MM]` after an explicit override, never as a duplicate row.
- `Of which cross-day repeats` = matched rows with `[reported …]`, including `代招岗位` rows. With the default previous-report skip it is normally 0.
- Use `MM-DD HH:MM` in markers so a repeat points at the exact run that reported it first; `MM-DD` alone is not enough on a multi-run day.

Soft duplicates: same normalized company + title + city with a different ID → `⚠️ possible duplicate`, or `⚠️ possibly applied MM-DD` when applied. Annotate only; never merge or change counts. Normalization rules are in `job-index-and-audit.md`.

Application marker: after the user confirms, append `[applied MM-DD]` to Notes and set `appliedOn`. Do not change the decision or counts.

Application staging markers (written by `job-apply` only):

- `[filled MM-DD]` — form complete and waiting for the user's Submit; `applyStatus: "filled"`, `appliedOn` still `null`.
- `[applied MM-DD]` — submit confirmed on the page; set `appliedOn`.
- `[apply blocked MM-DD]` — a blocker stopped the attempt; name it briefly. The same blocker must appear in Notes as `无法自动提交：<reason>`.
- Easy Apply rows never get these markers from the agent; the user applies and confirms them.

Cover letter: draft for every matched job when `common.isNeededCover` is `true` — Easy Apply and No Easy Apply alike, `代招岗位` rows included — whatever the page's `coverLetter` value says. Copy `cover-letter-template.md` exactly; fill only its placeholders from the page; leave unfillable placeholders unchanged and tell the user. Save the JSON plus `<First>_<Last>_<Role>_Cover_Letter.pdf` under `reports/cover-letters/<company-slug>/`. Never fabricate. Do not submit. If the template is missing, stop and tell the user to copy `cover-letter-template-example.md`.

## 12. Update an existing report

Only the current run's own file may be updated, and only by this run's later steps (`job-apply`, `linkedin-feed-jobs`). Never reopen or edit another run's report, and never merge two runs into one file.

Keep existing entries and evidence inside that file. Preserve `代招岗位` and `Feed-sourced jobs` sections and their rows. Add or correct only with new evidence. Never silently rewrite an old conclusion; state the reason when new config changes a decision. When the header's `结束时间` or apply-dedupe line becomes outdated, update those two lines.

When a config change reclassifies a job (for example a previously excluded third-party posting now passes and belongs in `代招岗位`), move the row to the correct table, keep its evidence and counts consistent, and state the reason in Notes. Never leave the same job in two tables.
