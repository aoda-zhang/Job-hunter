---
name: job-discovery
description: Search each configured job title on the platforms in sources with the local browser, record every result card in a job-audit list, merge and shallow-filter titles, then inspect real JDs and write the daily report. Three steps, each with its own reference document.
---

# Job Discovery

Run locally in this repository with the configured browser tools. No backend, database, CLI, CI or source adapters.

**One run = one report file**: `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/report.md` (`HHMM` = start time, `-2` / `-3` on collision). Never append to or rewrite another run's file and never write a day total.

## 1. Read config

Read `job-hunter.config.json` (Git-ignored). Never use the example as personal settings; if it is missing, tell the user to copy it and stop.

- `sources` — platform list **and order**; each entry needs a `platforms.<name>` block. It is not an unconditional run list: which platforms run is decided by `schedules` (§1.1).
- `common.searchTitles` — ordered titles, **one query per entry**. Required; stop and ask when empty.
- `common.countries` / `common.locations` — scope. Empty `locations` = the whole country.
- `common.lookbackHours`, `workModes`, `employmentTypes`, `seniority.include` — scope and filters.
- `common.jobTitles.include`, `technicalKeywords.*` — **matching only, never queries**.
- `common.jdLanguages.include` / `maxRequiredLevel` — accepted JD languages and optional CEFR caps. A German JD is never a Part 1 match; with `germanJdPass.enabled` it is deferred instead (below).
- `germanJdPass` — Part 2, the separate both-lan pass over German-language JDs: `enabled`, `reportFile`, `excludeGermanOnly` (skip only an explicit German-only requirement; a JD that is silent about languages passes) and `minStackMatches` (how many `common.technicalKeywords.include` terms the JD must show; the title gate already passed during the deferral). It works the whole list every run, one posting at a time, with no cap. Its audit, gates, queue and report format are `references/german-jd-pass.md`.
- `common.jobTitles.stackExclude` — optional string array; a title containing any of these **whole words/phrases** (case-insensitive) is removed in step 2 before any JD is opened, **unless** the title also contains a `stackIncludeOverride` phrase. This is a primary-stack gate: it intentionally beats the `jobTitles.include` guard. Use whole-word matching so `Java` does not match `JavaScript`.
- `common.jobTitles.stackIncludeOverride` — optional string array; if a title contains one of these frontend terms, a `stackExclude` hit does not remove it, and the row goes to JD review.
- `common.jobTitles.shallowExclude` — optional string array; a title containing any of these strings (case-insensitive) is removed in step 2 before any JD is opened, unless the normalized/translated title also contains a `jobTitles.include` phrase (that guard always wins).
- `common.jobTitles.earlyStrictMatch` — when `true`, step 2 also applies the strict title gate: a normalized/translated title without an include phrase (or with an exclude word) is removed before any JD is opened.
- `common.thirdPartyPostings`, `dedupe.*`, `report.*`, `sortBy`, `preferredReportLanguage`, `reportRepo`, `isNeededCover`.
- `common.saveMatchedJobs` — boolean (default `false`). When `true`, every vacancy that ends as `matched` is saved on its source platform, whether or not it is applied to. See §4.
- `platforms.<name>.search.queryMode` — `titles` (default) or `custom`. **There is no prompt mode.**

`applicant` and `applications` are runtime blocks.

### 1.1 Which platforms run comes from `schedules`, not `sources`

`sources` lists the configured platforms and their order. It is **not** a list every run must walk. Resolve this run's platform set before step 1:

1. Find the schedule block that triggered the run:
   - `schedules.linkedinJobSearch` → the LinkedIn job search. It covers every platform in `sources` that has **no** dedicated `<platform>JobSearch` block.
   - `schedules.indeedJobSearch` → `Indeed` only.
   - `schedules.linkedinFeedReview` → feed review only; it never runs job discovery.
2. For a manual request ("run today"), use today's local weekday (`0` and `7` are Sunday, `1` Monday … `6` Saturday) and include a platform only when its schedule block's `weekdays` contain today. A missing or empty `weekdays` means every day. `times` is advisory for a manual run (off-time is fine on a due day) and exact for a scheduled run. Platforms share a block only when they have no dedicated block of their own.
3. A platform whose schedule is not due today is not searched, not collected and not listed in the job-audit. Record it in the report header and in `searchedBySource` as `skipped (not scheduled today)`.
4. Only an explicit user request naming a platform ("also run Indeed today") may run it off-schedule; note that override in `limitations`.
5. Process the selected platforms in `sources` order. If no platform is due, stop and tell the user instead of searching one anyway.

`schedules.*` decides **which** platforms run; it never changes queries, filters, matching or reporting. With a single platform due, the report has one matched section and no empty section for the skipped one.

## 2. Prepare the run

Read these once, before the first platform:

- **previous-run set** — job IDs and canonical URLs in the merged list of the single most recent earlier **job-search** run's `<run>/job-audit.md`, every status included (matched, review, excluded, shallow-filtered, skipped). A feed-only run (`linkedin-feed-review` / `linkedin-feed-jobs`) writes no `job-audit.md` and is not the previous run for this set. Those cards are skipped and recorded only in this run's `job-audit`. Fall back to that job-search run's `report.md` tables only when its audit is missing or has no merged list, and say so in `limitations`.
- **applied set** — every application row in today's `reports/applications/YYYY-MM-DD.md`, keyed by normalized `company + title + city`; extended as this run applies. `reports/job-index.json` is legacy and is never read or written.

Scope: require one non-empty `common.countries`; non-empty `locations` limits to those cities. Never narrow silently.

Cross-source rules (`common.dedupe`):

- `crossSource: true` — the same `company + title + city` on two platforms is one vacancy: keep the first row, annotate the second `⚠️ same job on <source>`. Never merge rows or change a decision.
- `skipApplied: true` — a vacancy applied to on another platform is never opened or applied to again; it is shown only in `job-audit` as `applied on another platform (skipped)`.
- Extend the applied set as applications are confirmed, so a later platform sees them.
- With `crossSource: false`, only canonical URL / job ID dedupe applies.

## 3. The three steps

| Step | Document | Produces |
|---|---|---|
| **1 · Collect** | `references/step-1-collect.md` | `job-audit`: every card — company, title, link, job ID |
| **2 · Merge and shallow-filter** | `references/step-2-merge-filter.md` | one row per vacancy + who survives to step 3 |
| **3 · JD review** | `references/step-3-jd-review.md` | matched / review / excluded, apply fields, cover letters |

Run them in this order; never merge or reorder them. Step 1 finishes every source before step 2 starts. Step 3 opens exactly one posting at a time.

Platform mechanics live in `references/linkedin.md` and `references/indeed.md`; report structure lives in `references/daily-report-format.md`; run-log and audit fields in `references/job-index-and-audit.md`; the Part 2 German-JD deferral, queue and `both-lan.md` format in `references/german-jd-pass.md`.

## 4. Rules for every step

- **Strictly sequential, one tab for the whole run**: one query, one posting, one working tab. Create that tab once (or reuse a tab the user lent) and pass its id to every `navigate` / `eval` / `snapshot` / `click` call. `browse.navigate` with a URL but **no** `tab` opens a new background tab — never do that, and never open a second tab to try a fallback URL or a UI experiment. The `job-audit.md` file, not the open search page, is the record between steps, so keep using the same tab for every query, page turn and JD. Close any accidentally created tab immediately and record `tab hygiene` in `limitations`. Before the report is written, list the tabs and close every tab this run opened (the only exception is a `fill`-mode application tab the user must submit, which is reported as left open). Never batch-open cards or URLs, never loop over job IDs inside one call or script, never keep more than one job tab open.
- Search results are not evidence: recommendation and fallback blocks ignore the filters, and so do the `Viewed` strip and promoted / `Verified job` slots. Read the posted age printed on every card and drop anything already outside the lookback before it reaches the audit. Judge every posting from its own page.
- One source failure does not stop the run: record it in `limitations` and `searchedBySource`, continue, report it.
- **Trust signals: primary platform vs third party.** A `verify you are human`, CAPTCHA, `unusual activity` / `unusual traffic`, `automated access`, `are you a robot`, AI-agent warning, or forced re-login/2FA on a **primary platform page** (`linkedin.com`, `indeed.com`, `smartapply.indeed.com`, or the LinkedIn feed) stops the entire run immediately — no navigation, search, apply or retry; keep what is written and tell the user to take over. On a primary platform, also write `reports/runs/apply-halt-YYYY-MM-DD.json` with the time, platform, exact text and URL so no application can run later that day, and close every tab this run opened. The same signal on a **third-party / employer / ATS page** closes only that third-party tab, records the vacancy as `blocked: <exact signal>` in its `fields.json` and `help.json`, and continues with the next posting. Never retry that page; never treat it as a stop-all signal.
- **Language split**: the report follows `common.preferredReportLanguage`; every value sent to an employer — form fields, free-text answers, cover letters, uploaded documents — is **English only**, whatever that setting says.
- Never fabricate a listing, JD fact, field value or result. Never guess a private API or bypass access controls.
- **Save matched postings.** With `common.saveMatchedJobs: true`, every vacancy that ends as `matched` — normal matched rows and confirmed agency/third-party rows, including rows later submitted — gets exactly one Save/bookmark click on its own platform page. Saving is independent of `applications.enabled`, of the apply outcome and of whether the user ever applies: save it anyway. Save right after the classification decision, before any Apply control is used and before the tab closes. Never save `review`, `excluded`, expired or skipped rows, never save from a search-result card, never toggle an already-saved job off, never create an account or log in to save. A missing control or login wall is recorded as `not saved: <reason>` and does not stop the run. Ordering: classify → save → apply control.
- Discovery never fills or submits a platform one-click apply. When `applications.easyApply.enabled` is `true`, it records only the label and leaves the modal to `job-apply`; otherwise it may open the modal once read-only to record fields.

## 5. Outputs

1. **Report** — this run's file, in `common.preferredReportLanguage`, following `references/daily-report-format.md`: run header, summary, matched and submitted rows. Excluded and review rows never enter `report.md`; their status and reason live only in `job-audit.md`. The step-1 record is a separate `<run>/job-audit.md`; deferred German-JD rows go to `<run>/german-jd-audit.md`.
2. **Application log** — record every attempted application in `reports/applications/YYYY-MM-DD.md`; never write `reports/job-index.json`.
3. **Audit** — append one JSON line to `reports/runs/YYYY-MM-DD.jsonl` with real `runAt`, `finishedAt`, `durationSeconds`, `reportPath` and the fields in `references/job-index-and-audit.md`. Never write `finishedAt` in advance.
4. **Publish** — when `reportRepo` is set, run `.opencode/scripts/report-publish.sh <run-folder> reports/<YYYY-MM-DD>/<YYYY-MM-DD-HHMM>`; it pushes only that unit and arms the one-shot expiry timer. The publisher copies only report artifacts (`*.md`, `*.pdf`, per-vacancy `fields.json` / `cover-letter.json`) and drops hidden scratch files such as `.step2.py`, `.q1.tsv` or `.DS_Store`; keep those helpers in the run folder if you need them, they never leave the machine. Every publish is committed with the fixed message `test something`. Push only the run folder. Never publish the index, runs or applications. Published copies are temporary: the `report-cleanup` skill removes them after `common.reportExpiryHours` (default `0` = off). With `reportExpiryMode: "delete-repo"` the whole repo is deleted, so if the clone fails because the remote is gone, recreate it first with `gh repo create <owner>/<name> --public`, then push. A missing remote is expected, never a publish failure — never re-push expired content.
5. **Apply** — when `applications.enabled` is `true`, load `job-apply` after the report and index are written. Once Part 1 is published, the optional Part 2 (`job-apply` §1a, `germanJdPass.enabled`) works `german-jd-audit.md` and the queue, and writes `<run>/both-lan.md`; it never changes Part 1.
6. **Both-lan pass (Part 2)** — after 4–5, and only when `germanJdPass.enabled` and `applications.enabled` are `true`: `job-apply` §1a with `references/german-jd-pass.md`, output `<run>/both-lan.md`, then publish the run folder again. It never changes Part 1.
7. **Desktop copy** — the scheduled `daily-run.sh` wrapper copies every job-search phase automatically after the agent exits. When you started the run yourself (`JOB_HUNTER_RUN_STAMP` is unset), run `.opencode/scripts/copy-report-to-desktop.sh <run-folder>` once Part 1 and Part 2 are finished. The script reads `common.report.desktopCopy`: when `enabled` is `true` and the run started at/after `afterHour` (default `18`), it writes the run's report artifacts to `<directory>/JobHunter-<YYYY-MM-DD-HHMM>` (default `~/Desktop`). It never copies `reports/runs/` or `reports/applications/`; a failure is reported in `limitations` and never changes the report.

Report completion: report path and start time, scope, titles submitted, the step-1 funnel, skips, matched / Easy Apply / No Easy Apply, saved / not saved, applications filled / submitted / blocked, third-party postings, review, excluded, deferred German JDs, coverage and stop reason per source, limitations. Part 2 is reported separately: candidates, strong matches, submitted, blocked, Easy Apply submitted vs left to the user, queue size and the `both-lan.md` path.
