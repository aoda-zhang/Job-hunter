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
- If the submitted query lands on a semantic/AI landing result page (`origin=SEMANTIC_SEARCH_LANDING_PAGE`) or any list whose URL carries no date filter, that list is **unfiltered**: do not read its cards. Load the same title with the filtered URL from the platform reference and verify the pills first.

Platform mechanics: `linkedin.md`, `indeed.md`.

## 2. Filters

Apply the date filter from the effective lookback (`platforms.<name>.search.lookbackHours`, else `common.lookbackHours`) and verify it is active — date is scope and is always applied. Then apply only the filters that platform enables in `search.filters`.

Verify the active state before reading cards:

- LinkedIn: `Past 24 hours` and `Full-time` must both show as active pills.
- Indeed: the `Date` chip and the `Type of employment` selection must show as active.

If a filter cannot be applied, stop that source instead of reading unfiltered results. A dimension whose flag is `false` is read from the posting in step 3.

**Date is also a per-card gate.** Read the posted age printed on every card and drop a card whose age is already outside the effective lookback before it enters the audit; `Reposted <time>` counts as fresh. The pills only control the organic list — the `Viewed` strip, promoted / `Verified job` slots and unfiltered landing pages show older postings regardless. So never trust the pills alone: a card whose printed age is outside the window is `dropped: outside lookback`, not collected and never opened. When a card shows no age (`Viewed` cards often do not), keep it for step 3 to judge.

## 3. Pagination

Advance until results end or `maxPagesPerQuery` is reached. Stop when the page returns fewer cards than a full page, the platform reports no more results, or the same postings repeat. A login wall, CAPTCHA or rate limit on a primary platform is the stop-all rule, not a pagination stop.

Record the displayed result count verbatim (`99+ results`, `not shown` when absent) and the pages opened.

## 4. What to record

For every card, and nothing more:

| Field | Rule |
|---|---|
| Company | As shown on the card |
| Job title | As published, including `(m/f/d)` / `(all genders)` |
| Link | Canonical job URL |
| Job ID | Numeric ID (LinkedIn) / `jk` (Indeed) |
| Posted | The relative age printed on the card (`9 hours ago`, `Reposted 16h`, `1 month ago`); `not shown` when absent |
| Source | Platform name |
| Search titles | Every configured title that returned this card |

**Never insert a card by hand.** Every row must come from a page read in this run under the verified filters. When a page seems short or a count does not add up, re-read that page in the filtered list — never patch the list with cards remembered or copied from an earlier, unfiltered view.

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

Status in this step is one of `sent to JD review`, `previously reported`, `already applied (skipped)`, `applied on another platform (skipped)`, `dropped: outside lookback`. `removed by shallow filter` is added in step 2.

Finish with the counts line:

```markdown
This run: 2 search titles · 324 cards · 228 unique · 228 sent to JD review
```

Then move to `step-2-merge-filter.md`.
