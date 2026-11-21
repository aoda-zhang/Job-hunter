# Job Hunter

**Tell OpenCode what job you want. It searches the job platforms you configure — LinkedIn plus any other site you can reach in your own browser — opens each remaining vacancy, filters it against your config, and writes a daily Markdown shortlist.**

**English** · [简体中文](README.zh-CN.md) · [Deutsch](README.de.md)

## 1. What it does

Job Hunter is a small set of OpenCode instructions (one agent + six skills) plus one personal config file. There is no application code: no backend, database, CLI, CI or API key.

A run does four things:

1. **Searches** every platform listed in `sources`, in that order, with the query each platform is configured to use (LinkedIn: one natural-language prompt; Indeed: short keyword phrases).
2. **Narrows** the results with each platform's own filters taken from your config: date posted, employment type, work mode, seniority and location.
3. **Inspects** each remaining vacancy page — the real posting, not just the search card — and skips postings that are closed or no longer accepting applications.
4. **Classifies and reports** every vacancy as matched, needs review, or not matched, then saves the result to `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM.md` — one file per run, named to the minute, never merged across runs.

It never applies for you, never messages recruiters, and never changes your account settings. It uses the browser session you are already logged in with.

## 2. How it works

```mermaid
flowchart TD
    A[job-hunter.config.json] --> B[Job Hunter agent]
    B --> C[Configured platforms<br/>sources: LinkedIn, Indeed, …]
    C --> D[Each platform's search<br/>LinkedIn prompt, Indeed queries]
    D --> D2[Each platform's own filters<br/>date, type, mode, seniority]
    D --> E[Open each vacancy page]
    E --> F{Job still open}
    F -->|closed| X[skipped and counted]
    F -->|open| G[Check title, employer, JD language,<br/>keywords, mode, type, seniority]
    G --> H[matched / review / not_matched]
    H --> I[reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM.md]
```

The agent checks the dimensions in a fixed order and stops at the first confirmed mismatch. When the page does not clearly prove a match or a mismatch, the vacancy goes to **review** instead of being rejected.

## 3. What you need

| Requirement | Notes |
|---|---|
| OpenCode | installed, opened on this repository |
| Browser tool | a browser integration enabled in OpenCode; this repository does not install or configure one |
| Job platforms | every platform you list in `sources`, already logged in in that browser |
| Anything else | nothing — no Node.js, npm, database or CI |

## 4. Quick start

```bash
cp job-hunter.config.example.json job-hunter.config.json
```

Edit `job-hunter.config.json` — it is Git-ignored, so your preferences stay local:

1. **`common.jobSearchPrompt`** — one natural-language sentence for LinkedIn: where, which role, which stack, how recent.
2. **`common.countries` / `common.locations`** — where to search. Empty `locations` means the whole country.
3. **`common.jobTitles.include`** — the titles you accept; used for matching and for Indeed's default queries.
4. **`common.jdLanguages.include`** and **`common.technicalKeywords`** — the language and stack you can work with.
5. Optionally set `common.workModes`, `common.employmentTypes`, `common.seniority` and `common.thirdPartyPostings` (`separate` by default).
6. Keep `sources` in the order you want them searched — `["LinkedIn","Indeed"]` runs LinkedIn first.

Then:

1. Open this folder in OpenCode.
2. Select the **Job Hunter** primary agent (`Tab` to switch agents).
3. Ask in plain language, e.g. *"Find today's jobs"* or *"Refresh the report, only remote roles"*.
4. The agent drives the browser, then writes `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM.md` (`HHMM` = that run's start time). Open it and scan the tables.

You only ever talk to the Job Hunter agent. It loads `job-discovery` by itself; you never pick a skill manually.

> **Queries are per platform.** LinkedIn receives `common.jobSearchPrompt` verbatim; Indeed receives the short phrases in `platforms.Indeed.search.queries` (or one query per title). Both are configured, never invented at runtime. `jobTitles` and `technicalKeywords` are used to *match* results, not to *search*.
>
> **Filters come from the config, not from the prompt.** Writing "last 24 hours" in the prompt is not reliable; the agent sets the platform's "Date posted" filter from the configured lookback and verifies it before reading results. On Indeed it also maps the JD language, employment type and remote preference to those filters.

## 5. Configure your search

The file has three layers: `sources` (run order), `common` (shared preferences), `platforms` (per-platform settings). `applicant`, `applications` and `notifications` are shared runtime blocks, and `schedules` holds the launchd timers.

| Field | Required | What it does |
|---|---|---|
| `sources` | yes | Platforms to search **in this order**. `["LinkedIn","Indeed"]` means LinkedIn first, then Indeed. Each entry needs a `platforms.<name>` block. Dedicated references ship for `LinkedIn` and `Indeed`; a platform without a reference is skipped, not guessed. |
| `common.countries` | yes | Country-level scope, e.g. `["Germany"]`. Used to validate and describe the search scope, not to build the query. |
| `common.locations` | no | Optional cities inside those countries. Empty or absent = the whole country. |
| `common.lookbackHours` | yes | Posting window in hours. Drives each platform's date filter and is checked again on each posting. |
| `common.jobSearchPrompt` | yes | The natural-language query used by platforms with `queryMode: "prompt"` (LinkedIn). Sent verbatim. |
| `common.jobTitles.include` | yes | Accepted title variants, used for matching, the card pre-filter and `queryMode: "titles"`. |
| `common.jdLanguages.include` | yes | Accepted JD languages, e.g. `["English"]`. Indeed maps it to its `Language` filter. |
| `common.jdLanguages.acceptGermanJdWithEnglishWorkingLanguage` | no | When `true`, a German JD still matches if it explicitly names English as the working, team or company language. |
| `common.jdLanguages.maxRequiredLevel` | no | Optional explicit language-level limits, e.g. `{"German": "A2", "English": "C1"}`. If the JD requires a level above the configured one, the job is excluded as `language requirement`. Bare "German required" counts as B1; "nice to have/plus/optional" is not a requirement. |
| `common.technicalKeywords.include` | yes | Technologies to look for in the JD. |
| `common.technicalKeywords.matchMode` | yes | `any` = one keyword is enough; `all` = every keyword must appear. |
| `common.workModes` / `common.employmentTypes` / `common.seniority.include` | no | Optional matching filters. Listing all values or leaving the list empty = filter off. |
| `common.thirdPartyPostings` | no | `separate` (default) keeps confirmed staffing-agency postings that hire for a third-party client in a dedicated `代招岗位` section; `include` lists them with normal matches; `exclude` drops them. Unclear cases go to review. |
| `common.skipPreviousReport` | no | Default `true`. Skips every job already listed in the previous daily report. |
| `common.dedupe.crossSource` | no | Default `true`. Treats the same normalized company + title + city on LinkedIn and Indeed as one vacancy and annotates the second one. |
| `common.dedupe.skipApplied` | no | Default `true`. Once a vacancy is applied to on one platform, it is skipped on every other platform and never applied to again. |
| `common.report.splitBySource` | no | Default `true`. Writes the daily report as one matched section per platform, in `sources` order, each split into Easy Apply / No Easy Apply. |
| `common.isNeededCover` | no | When `true`, a job kept in the report (`matched` or `review`) whose JD requires a cover letter gets one. The agent drafts it from the JD and CV and can render a PDF with the `cover-letter` skill (`python3 .opencode/skills/cover-letter/scripts/render.py <json>`). Default `false`. |
| `common.reportRepo` | no | Optional Git URL. When set, the day's report is committed and pushed there after each run. |
| `common.sortBy` / `common.sortDirection` | no | Ordering inside each part (Easy Apply, No Easy Apply), after prompted rows; submitted rows use the global 已提交 section order. `companySize` with `asc` or `desc`; omit for discovery order. |
| `common.preferredReportLanguage` | no | Language of the daily report and the summary email body, e.g. `English`, `German`, `Chinese`. Defaults to `English`. |
| `applicant` | no | Identity used to fill external applications: `firstName`, `lastName`, `phone`, `email`, `currentCity`, `linkedinUrl`, `portfolioUrl`, `cvPath`, `availableInGermanyFrom`, `governmentEmployee`. Missing required identity fields stop the apply run; missing screening answers only block the affected job. |
| `applications` | no | Application policy. `enabled`; `externalApply` = `true` (fill, upload and submit) / `false` (inspect only); legacy `off` / `inspect` / `fill` (stops before Submit) / `submit` still accepted; `scope` = `matched` (default) / `review` / `all`; `excludeThirdParty` (default `true`); `requireNoAccount` (default `true`); `requireExternalRedirect` (default `true`); `maxPerRun` (number or `null`); `coverLetterMode` = `never` / `required-only` / `always`; `screening` holds the answers used on forms. A platform one-click apply has no key and is always manual. |
| `platforms.LinkedIn.enabled` / `.premium` | no | `premium: true` orders matches showing `You'd be a top applicant` first inside their part. `enabled: false` skips the platform. |
| `platforms.LinkedIn.search.queryMode` | no | `prompt` (default, uses `common.jobSearchPrompt` verbatim), `titles` or `custom`. |
| `platforms.LinkedIn.feedReview` | no | Feed pass settings: `lookbackHours`, `maxPosts`, `excludeTopics`, `replyLanguage`. |
| `platforms.LinkedIn.feedJobs` | no | Hiring-post search: `enabled`, `lookbackHours` (feed-post window; falls back to `common.lookbackHours`), `searchKeywords`, `maxQueries`, `maxPagesPerQuery`, `maxScreens`, `locationTerms`, `includeRecentFeed`. |
| `platforms.Indeed.enabled` | no | `false` skips Indeed while keeping it in `sources`. |
| `platforms.Indeed.domain` | no | e.g. `de.indeed.com`. Must match `common.countries`. |
| `platforms.Indeed.search.queryMode` | no | `custom` (default for Indeed: use `search.queries`), `titles` (one query per `common.jobTitles.include`) or `prompt`. |
| `platforms.Indeed.search.queries` | no | Short keyword phrases, e.g. `["Frontend Developer","React Developer"]`. Indeed handles short phrases far better than a long paragraph. |
| `platforms.Indeed.search.maxQueries` / `.maxPagesPerQuery` | no | Page budget for the source. |
| `platforms.Indeed.search.lookbackHours` | no | Overrides `common.lookbackHours` for Indeed only — currently `168` (7 days) while LinkedIn stays at 24 hours. |
| `platforms.Indeed.search.filters` | no | Which Indeed controls to bind: `date` (always on), `employmentType` (on — selects `Full-time` from `common.employmentTypes`), `language` (off — read the JD), `remote` (off), `quickApply` (off — it hides external-ATS jobs). A dimension with `false` is judged from the posting page. |
| `notifications.email` | no | Optional SMTP block for run-summary emails. Off by default; when `enabled`, one summary is sent after each run. |
| `schedules.jobSearch` | no | Daily job search launchd job. `times` is an array of `HH:MM` strings; `weekdays` is an optional array of launchd weekdays (`0`–`7`, `1` = Monday, `5` = Friday; empty = every day); an empty `times` array disables the job. `timezone` must match the system. |
| `schedules.linkedinFeedReview` | no | Feed pass launchd job: `times`, `weekdays`, `timezone`. An empty `times` array disables the separate feed job. |

Notes:

- `lookbackHours` is a number. It is mapped to the closest date filter that platform offers and that fully covers the window (LinkedIn: ≤24 → past 24 hours, ≤168 → past week, ≤720 → past month; Indeed: 24h / 3 / 7 / 14 days), and each posting is checked again on its own page.
- A dimension is active only when you restrict it. Listing all three work modes, all employment types, or leaving `seniority.include` empty means "no filter".
- `platforms.LinkedIn.feedReview.excludeTopics` is the only exclusion list, covering both topics and content types. The skill has no built-in exclusion list; an empty array disables these exclusions (the time window still applies).
- Scope vs filter: country, city and posting date decide *what to search*. Only the dimensions above decide whether a vacancy *matches*.
- Cross-platform order: run `sources` in order. A vacancy already applied to on LinkedIn is not opened on Indeed, not listed again and never applied to twice (`common.dedupe.skipApplied`).
- Current search shape: LinkedIn uses a **24-hour** window (`common.lookbackHours: 24`); Indeed uses **7 days** (`platforms.Indeed.search.lookbackHours: 168`). Both judge the JD itself — Indeed gets short keyword queries, applies the `Date` and `Full-time` filters, and reads JD language, work mode and keywords from each posting (`filters.language: false`, `filters.remote: false`).
- Application policy: **one-click apply rows stay yours** (LinkedIn Easy Apply, Indeed Quick application / Schnellbewerbung) — the agent never opens them. Every external, non-one-click match is filled and, with `externalApply: true`, submitted once by `job-apply`; with `false` it only inspects the fields. A vacancy already applied to on the other platform is skipped, so nothing is submitted twice. Remember `applicant` and `applications.screening` must be filled for the agent to submit; a missing required answer blocks that job instead of guessing.

The daily job runs as **two separate OpenCode sessions in a fixed order** — LinkedIn first (discovery + external applications + feed hiring posts), then Indeed — so neither session has to hold both platforms at once. `JOB_HUNTER_PHASES=linkedin zsh .opencode/scripts/daily-run.sh` runs a single phase; the default is `linkedin,indeed`. Each phase merges into the same daily report and index, and Indeed skips anything already applied to on LinkedIn.

**Schedule.** Editing `schedules.jobSearch` in the config does not change launchd by itself. After changing `times`, `weekdays` or `timezone`, run `.opencode/scripts/apply-schedule.sh` (or ask the agent to change the schedule). launchd uses the Mac's local time, so `timezone` must match the system timezone. An empty `times` array unloads and removes the job search schedule; adding times recreates it.

The LinkedIn feed has its own launchd timer. Set `schedules.linkedinFeedReview.times` to an array of `HH:MM` values, optionally restrict it with `.weekdays` (`[1,2,3,4,5]` = Monday–Friday), and run the same script; an empty array disables that job. Each run reads the Recent feed once without checking the following list: it replies only to posts whose author role matches `common.jobTitles.include` and whose author location is confirmed inside `common.countries`/`common.locations`, with no daily minimum (zero is valid), adds hiring posts whose title and stated location match the config to `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM.md`, emails the replies and job rows when notifications are enabled, and publishes `reports/linkedin-feed/YYYY-MM-DD.md` plus the updated daily report to `common.reportRepo`.

## 6. How jobs are filtered

Checks run in this order and stop at the first confirmed mismatch:

1. Posting validity — 404, redirect away from the job, "no longer accepting applications".
2. Job title — same role family as `jobTitles.include`.
3. Poster type — record direct, third-party or unclear; a confirmed third-party posting passes and is listed in the separate section (or is excluded when configured).
4. JD language — the language actually used in the description.
4b. Language requirement level — when `jdLanguages.maxRequiredLevel` is set, an explicit JD requirement above your configured level is a mismatch (`language requirement`).
5. Technical keywords — following `matchMode`.
6. Work mode — only when `workModes` is a real subset.
7. Employment type — only when `employmentTypes` is a real subset.
8. Seniority — only when `seniority.include` is a real subset.

| Result | Meaning | Where it appears |
|---|---|---|
| `matched` | every active dimension is confirmed on the page | main table; confirmed third-party postings in `代招岗位` |
| `review` | the page does not prove match or mismatch (short, missing, truncated, mixed language) | review table |
| `not_matched` | at least one active dimension clearly fails | excluded table with the exact reason |

Before opening a page, the agent does a cheap card pass: titles that clearly name a different function (sales, marketing, finance, HR, design, SAP admin, …) or that are clearly outside your country/city are skipped and only counted. Ambiguous, truncated or multi-role titles are still opened.

The agent works **strictly sequentially**: one search query at a time, one posting at a time, one browser tab at a time. It opens a job, reads it, classifies it, applies or inspects it, records the row, closes the tab, then moves on. It never batch-opens job cards or job URLs and never runs parallel browser actions — a slow serial pass is the intended behaviour.

There is no score, no ranking by candidate fit, and no filtering on salary, years of experience, visa or industry. Each platform's matched section is split into workflow parts: **Easy Apply** (one-click platform apply — you apply manually) and **No Easy Apply** (external forms the agent fills; with `externalApply: true` it also submits them), then a final **已提交** / **Submitted** part holding every job whose application went through, so submitted rows are never mixed with inspected ones. With `platforms.LinkedIn.premium`, LinkedIn matches showing **`You'd be a top applicant`** are ordered first inside their part; a failed check still excludes the job. The split never changes whether a job matches.

A vacancy applied to on LinkedIn is skipped on Indeed, and the other way round: one vacancy is applied to once. Duplicates that were not applied to are annotated, never merged.

## 7. Reports

| Output | Path |
|---|---|
| Each discovery run | `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM.md` |
| LinkedIn feed review | `reports/linkedin-feed/YYYY-MM-DD.md` |
| Cover letter drafts | `reports/cover-letters/<company-slug>/<jobId>.md` and `<...>.pdf` |
| Interview preparation | `reports/interviews/<company-slug>/` |

The daily report is grouped by platform in `sources` order (LinkedIn first, then Indeed). Inside each platform the matched jobs are split into **Easy Apply** and **No Easy Apply** parts (prompted LinkedIn Premium rows first inside each part, then company size), and every submitted row leaves its source section for a single **已提交** section placed just before the excluded jobs. The run summary has one column per platform plus a total. A separate `代招岗位` table follows when confirmed third-party postings pass the same checks, then a review table when needed, and the excluded jobs with the exact reason last. For the No Easy Apply part, the agent fills the third-party form and, with `externalApply: true`, submits it; with `fill` it leaves the tab open for your Submit. Every job table starts with the company name, then notes, apply-form status and link; the `Source` column is last because each section already names the platform. Any external job that could not be submitted automatically carries `无法自动提交：<reason>` in Notes.

**Matched and excluded tables** each include two extra application-process columns:

- **Easy Apply** — `Yes`/`No`/`Unknown`: whether the page shows a one-click apply button on the platform (LinkedIn "Easy Apply", Indeed "Quick application" / "Schnellbewerbung"). Used for the workflow split (Easy Apply vs No Easy Apply); the split is never a filter.
- **Cover letter** — `Yes`/`No`/`Unknown`: whether the page or application form explicitly says a cover letter is required. When `Yes`, the job remains in the report, and `common.isNeededCover` is `true`, the agent drafts the content and can render a PDF via the `cover-letter` skill (small JSON + fixed renderer), saving it under `reports/cover-letters/<company-slug>/`. The `.md` template remains the content baseline. It never auto-submits.

Reports follow the fixed format reference at `.opencode/skills/job-discovery/references/daily-report-format.md` and are written in `common.preferredReportLanguage` (default `English`). The reference fixes the structure; only the human-readable text is translated.

`job-hunter.config.json`, `reports/daily/`, and `cover-letter-template.md` are Git-ignored. If you set `common.reportRepo`, only that day's report is committed and pushed to your chosen repository after each run.

**Local memory.** Three more files stay on your machine and are never pushed:

| File | Purpose |
|---|---|
| `reports/job-index.json` | Every vacancy ever inspected, its latest status, `easyApply`, `coverLetter`, and the date you applied |
| `reports/runs/YYYY-MM-DD.jsonl` | One audit line per run: result count, pages opened, stop reason, all counters |
| `cover-letter-template.md` | Your personal cover letter content baseline (root). The agent uses it for wording and fills the job-specific parts; the `cover-letter` skill renders the PDF |

The index is what makes daily runs safe: a vacancy you already applied to is skipped before it is opened, repeats from any earlier day are tagged `[reported MM-DD]`, and the same role posted under a different job ID is flagged `⚠️ possible duplicate`. The audit log is what makes coverage measurable: if a platform showed 300 results and only 120 were inspected, the log records where the rest went and why pagination stopped.

Tell the agent "I applied to X" and it records `appliedOn`; every later run skips that vacancy.

**Email.** Set `notifications.email` in `job-hunter.config.json` (off by default). When enabled, the agent loads the `email-notify` skill after each run and sends one summary with the run time, counters and report path — no job details. The body follows `preferredReportLanguage`; the subject stays ASCII English. The exact layout is fixed by `.opencode/skills/email-notify/references/email-template.md`. Use `security: "ssl"` on port 465 or `"starttls"` on 587. The SMTP password lives in the config, so run `chmod 600 job-hunter.config.json`. Validate without sending:

```bash
.opencode/skills/email-notify/scripts/send-email.sh --check
```

## 8. Interview preparation (phase 2)

After you receive an interview invitation, tell the same agent which company and role. It loads `company-research`, reads the vacancy from your report or its original URL, and produces:

- `company-research.md` — business, products, customers, markets
- `role-analysis.md` — what this specific role expects
- `interview-preparation.md` — tailored answers and likely questions

This phase is manual and never runs during daily discovery.

## 9. Repository layout

```
.opencode/agents/job-hunter.md                    the agent you talk to
.opencode/scripts/daily-run.sh                    launchd entry point
.opencode/scripts/apply-schedule.sh               sync the schedule config to launchd
.opencode/scripts/feed-review-run.sh             feed review launchd entry point
.opencode/skills/job-discovery/SKILL.md           phase 1: search, filter, report
.opencode/skills/job-discovery/references/        report format, index/audit rules
.opencode/skills/job-discovery/references/        linkedin.md, indeed.md,
                                                  _template.md
.opencode/skills/job-apply/SKILL.md               fill external ATS applications, stop before Submit
.opencode/skills/linkedin-feed-review/SKILL.md    feed posts worth replying to
.opencode/skills/linkedin-feed-jobs/SKILL.md      feed hiring posts into the daily report
.opencode/skills/company-research/SKILL.md        phase 2: research and interview prep
.opencode/skills/cover-letter/                     JSON → tailored cover letter PDF
.opencode/skills/email-notify/                    run-summary email via SMTP
job-hunter.config.example.json                    template to copy
job-hunter.config.json                            your settings (git-ignored)
reports/daily/                                    daily reports (git-ignored)
reports/linkedin-feed/                            feed review reports (git-ignored)
reports/job-index.json                            seen jobs and applied dates (git-ignored)
reports/applications/                             external application log, personal data (git-ignored)
reports/runs/                                     run audit logs (git-ignored)
reports/interviews/                               phase 2 output
```

## 10. Troubleshooting

| Symptom | Cause and fix |
|---|---|
| No report appears | Config missing, `common.jobSearchPrompt` empty (for a `prompt` platform), or no browser tool. The agent is instructed to say which one. |
| "Browser tool unavailable" | Enable a browser integration in OpenCode. This repository does not ship or configure one. |
| The run stops at login or CAPTCHA | Log in to that platform yourself in that browser, then rerun. The agent must not bypass it. |
| German jobs are excluded | `common.jdLanguages` only accepts English. Set `acceptGermanJdWithEnglishWorkingLanguage: true`, or add `German`. |
| Too few results | Widen `common.jobTitles`, use `matchMode: "any"`, reduce the keywords, increase `common.lookbackHours`, or add more `platforms.Indeed.search.queries`. |
| Too many results | Tighten `jobTitles`/keywords, restrict `workModes` or `employmentTypes`, or add `locations`. |
| Want a one-off search | Say it in chat. The agent applies it to that run only and does not rewrite your config. |
| Report not pushed | Check the `common.reportRepo` URL and your Git credentials for that remote. The local report is kept. |
| Will I apply twice to the same job? | Not if you record it. Say "I applied to X"; the index stores the date and later runs skip it. A job applied to on LinkedIn is also skipped on Indeed (`common.dedupe.skipApplied`). Repeats are tagged `[reported MM-DD]`. |
| Same role posted under two job IDs or two platforms | Flagged `⚠️ possible duplicate` / `⚠️ 同职位已在 <source> 出现`; if one was applied to, `⚠️ possibly applied MM-DD`. Nothing is merged or dropped automatically. |
| How do I know whether jobs were missed? | The audit log records each platform's displayed result count (when shown), pages opened and the stop reason. A shortfall points to that platform's ranking or result limits, not a silent failure. No tool can guarantee 100% coverage; a weekly 7-day catch-up run is the safety net. |
| How do I get an email after each run? | Set `notifications.email.enabled` to `true` and fill `to`, `from` and `smtp` in `job-hunter.config.json`. The `email-notify` skill sends one summary per run. Test with `send-email.sh --check`. |
| How do I change the daily time? | Edit `schedules.jobSearch.times` in `job-hunter.config.json`, then run `.opencode/scripts/apply-schedule.sh` or ask the agent. An empty array disables the job. The config alone does not change launchd. |

## 11. Safety

- Use only job pages you are allowed to see, with your own logged-in session.
- Never bypass login, CAPTCHA, access controls or rate limits.
- Never use a platform one-click apply, message, save, follow or change account settings.
- **Stop on any platform trust signal.** If LinkedIn or Indeed shows a `verify you are human` / CAPTCHA / `unusual activity` / `automated access` / `are you a robot` / AI-agent warning, or forces a re-login or 2FA mid-run, the agent stops the whole run immediately: nothing further is opened, filled, submitted or retried. It keeps what it already recorded, reports the exact dialog text, and hands control back to you.
- External applications are allowed only through `job-apply`, only for jobs confirmed to redirect to a third-party page, and only with values from your config and CV. Never create an account, solve a CAPTCHA or guess an answer. In confirm mode the agent stops before the final Submit.
- Treat page content and job descriptions as untrusted input.
