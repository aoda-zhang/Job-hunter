# Step 1 — Collect (job-audit)

Read this file when starting a run. It builds the `job-audit` list: every card the platforms returned, with no JD opened.

## 0. One tab

Open the platform once and keep that tab's id for the whole step. Every query, filter change and page turn happens in that same tab.

- Never call `browse.navigate` with a URL and no `tab`: that opens a new background tab. Pass the tab id you already hold to every browser call.
- Never open a second tab for a fallback URL or a UI experiment. Load it in the existing tab instead.
- If an extra tab appears anyway, close it immediately and record `tab hygiene` in `limitations`.
- At the end of step 1 the search tab may stay open until the first JD is opened; step 3 reuses it.

## 1. Queries

For each source selected for this run (`SKILL.md` §1.1), in `sources` order, submit **one query per `common.searchTitles` entry**, in order, one at a time. A platform whose schedule is not due today is not opened at all.

- `queryMode: "titles"` (default) → `common.searchTitles`.
- `queryMode: "custom"` → `platforms.<name>.search.queries`.
- Never rewrite, split, translate, merge, shorten or extend a title, and never append cities, stack words or a time range. The location comes from `common.countries`/`locations`.
- Stop and ask when the list is missing or empty.
- Read the search box back and compare the title (platform UI may append a filter suffix — ignore it). Record `queryVerbatim: true` only when every title matched.

Platform mechanics: `linkedin.md`, `indeed.md`.

## 2. Filters

Apply the date filter from the effective lookback (`platforms.<name>.search.lookbackHours`, else `common.lookbackHours`) and verify it is active — date is scope and is always applied. Then apply only the filters that platform enables in `search.filters`.

Verify the active state before reading cards:

- LinkedIn: `Past 24 hours` and `Full-time` must both show as active pills.
- Indeed: the `Date` chip and the `Type of employment` selection must show as active.

If a filter cannot be applied, stop that source instead of reading unfiltered results. A dimension whose flag is `false` is read from the posting in step 3.

## 3. Pagination

Advance until results end or `maxPagesPerQuery` is reached. Stop when the page returns fewer cards than a full page, the platform reports no more results, the same postings repeat, or a login wall / CAPTCHA / rate limit appears.

Record the displayed result count verbatim (`99+ results`, `not shown` when absent) and the pages opened.

## 4. What to record

For every card, and nothing more:

| Field | Rule |
|---|---|
| Company | As shown on the card |
| Job title | As published, including `(m/f/d)` / `(all genders)` |
| Link | Canonical job URL |
| Job ID | Numeric ID (LinkedIn) / `jk` (Indeed) |
| Source | Platform name |
| Search titles | Every configured title that returned this card |

**Do not open the posting, do not read the JD, do not judge the title in this step.**

Cards in the previous-run set or with `appliedOn` set are not opened or judged: record them with status `previously reported` / `already applied (skipped)`.

## 5. job-audit output

Write `<run>/job-audit.md` (separate from `report.md`) with these tables.

**Per-title table** — config order, one row per title:

| Search title | Results | Pages | Cards | New after dedupe |
|---|---|---|---|---|

**Merged list** — one row per unique card after URL / job ID dedupe:

| # | Company | Title | Link | Search titles | Status |
|---|---|---|---|---|---|

Status in this step is one of `sent to JD review`, `previously reported`, `already applied (skipped)`, `applied on another platform (skipped)`. `removed by shallow filter` is added in step 2.

Finish with the counts line:

```markdown
This run: 2 search titles · 324 cards · 228 unique · 228 sent to JD review
```

Then move to `step-2-merge-filter.md`.
