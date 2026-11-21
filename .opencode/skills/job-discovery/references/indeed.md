# Indeed

Reference for `sources: ["Indeed"]`, configured by `platforms.Indeed` (`enabled`, `domain`, `search.*`). Any country domain works: `de.indeed.com`, `indeed.com`, `uk.indeed.com`.

The UI varies by country, language and A/B test, and changes often. Confirm a control exists on the live page before relying on it; if it is missing, use the stated fallback instead of inventing one.

## 1. Search entry

- Domain: `platforms.Indeed.domain` when set, otherwise the domain matching `common.countries` (`Germany` → `de.indeed.com`). Never reuse job IDs or URLs across domains.
- Location field: `common.locations` when non-empty, otherwise the country name or empty for country-wide.
- Queries: resolve from `platforms.Indeed.search` (`SKILL.md` §3). `queryMode: "titles"` (default) submits one query per `common.searchTitles` entry, one at a time; `custom` uses `search.queries`. There is no prompt mode. Indeed takes short keyword phrases — never submit a natural-language paragraph.
- One query per search. Re-submitting replaces the active filters, so verify them again after every new query.
- `search.lookbackHours` overrides `common.lookbackHours` for Indeed only.

## 2. Filter mapping

Apply the `Date` filter first and verify it is visibly active next to the search bar — date is scope, so `filters.date` is always on. Then apply only the matching filters enabled in `platforms.Indeed.search.filters`:

| Flag | Indeed control | Current setting |
|---|---|---|
| `date` | `Date` | on |
| `employmentType` | `Type of employment` → `Full-time` from `common.employmentTypes` | **on** |
| `language` | `Language` (`lang=en`) | off — read the JD instead |
| `remote` | `working from home` | off — read the posting |
| `quickApply` | `Quick application` | off — it hides external-ATS postings |

Any dimension whose flag is `false` is judged from the posting itself, exactly like LinkedIn. Turning `employmentType` on does not replace the JD check: a posting that states another employment type is still a mismatch.

| Config | Indeed control | Notes |
|---|---|---|
| effective lookback (`common.lookbackHours`, or `search.lookbackHours` when set) | `Date` filter | **Always applied** — date is scope, not match. `Last 24 hours` / `Last 3 days` / `Last 7 days` / `Last 14 days`, never a narrower window than configured. |
| `common.employmentTypes` | `Type of employment` | Applied only when `filters.employmentType` is `true`. |
| `common.workModes` | `working from home` (Remote) | Only when `filters.remote` is `true`, and only when the set is exactly `["Remote"]`. |
| `common.jdLanguages.include` | `Language` | Only when `filters.language` is `true`. Judging the JD itself is always preferred. |
| `common.technicalKeywords.include` | `Programming language` | Optional convenience filter; never needed, and not mapped by default. |
| `common.seniority.include` | — | No equivalent. Judge from the title or explicit level wording. |
| `common.countries`, `common.locations` | location field | Country comes from the domain; put configured cities in the field. |

`filters.date` and `filters.employmentType` are the only two that should normally be on: the date defines scope, and full-time is reliable and cheap to bind. Keep `language`, `remote` and `quickApply` off so no valid JD is silently dropped by Indeed's buckets; judge those on the posting page instead.

Verified URL parameters — valid shortcuts, but only after confirming the page shows the same selection:

| Parameter | Filter | Example |
|---|---|---|
| `fromage` | Date posted | `fromage=1` (24h), `3`, `7`, `14` |
| `lang` | JD Language | `lang=en`, `lang=de` |
| `jt` + `sc=0kf%3Aattr%28CF3CP%29%3B` | Employment type = Full-time | `jt=fulltime` alone may not register in the UI; pair it with the attribute or select `Full-time` in the panel, then confirm the chip shows a count |
| `sc` | Home office / remote | `sc=0kf%3Aattr%28DSQF7%29%3B` |
| `iafilter` | Quick application only | `iafilter=1` |
| `radius` | Radius in km around the location | `radius=35` |
| `sort` | Sort order | `sort=date` |
| `start` | Pagination offset | `start=15`, `start=30` |
| `vjk` | Job selected in the detail pane | `vjk=<jk>` |
| `q`, `l` | Query and location | `q=React+Developer&l=Deutschland` |

Do not add filters that are not in the config (salary, company rating, urgency, education, industry).

## 3. Result extraction

The results page is a split view: a card list on the left, the selected job's description on the right. Selecting a card updates `vjk` in the URL without a page load.

**Step 1 reads cards only.** Extract the `jk`, canonical URL and card fields; do not select cards or read JDs. Step 3 does the per-posting work.

**One query, one posting, one tab (step 3).** Run one query at a time and finish its pages before the next query. Process cards strictly in order: select one card (or open one `/viewjob?jk=` tab), read the JD, classify it, take the apply/inspect action, write the row, close the tab, then move to the next. Never batch-open several `jk` values, never loop over multiple job pages inside one script, and never keep more than one job tab open. A batch pass is a defect even if the rows look right.

- Job key: `jk` on the card link or apply button, usually 16 hex characters. Read it from the anchor (`a.jcs-JobTitle`, attribute `data-jk`, or `id` = `job_<jk>` / `sj_<jk>`). A card without `jk` is not usable — skip it and count it as a card skip.
- Canonical URL: `https://<domain>/viewjob?jk=<jk>`. Strip `pagead`, `rc/clk`, `vjs`, `tk`, `xkcb`, `from`, `vjk` tracking.
- Card fields: title, company, location or remote wording, salary range when shown, employment type, benefit tags, company rating, `New` badge, `Urgently needed`, `Advertisement` label.
- Sponsored cards repeat organic results and are labelled `Advertisement`; their links contain `/pagead/clk`. Deduplicate by `jk` before opening anything.
- Two DOM variants ship in rotation: anchors with `id="job_<jk>"` and `/rc/clk?jk=` hrefs, or `id="sj_<jk>"` with `data-jk` and `/viewjob?jk=`. Never depend on the id prefix; always read `data-jk` or parse `jk` from the href.
- The detail pane carries the full JD (`Job description` / `Full job description`) and the apply control. Read both there instead of opening a second tab.

## 4. Pagination

- About 15 cards per page. Advance with `start=15`, `start=30`, … or with the pagination control when it is rendered.
- The pagination element is often empty even when thousands of results exist, so never conclude "no more results" from a missing pager. Stop only when the `start` page returns no new `jk` values.
- Respect `search.maxPagesPerQuery`. Stop earlier when results fall outside the window, the same `jk` set repeats, or an access boundary appears.
- `common.searchTitles` × `search.maxPagesPerQuery` is the hard page budget for this source.

## 5. Freshness

Indeed does not show a posting date on the card or in the detail pane. Freshness therefore comes from three sources only:

1. the `Date` filter (page-level, verified active),
2. the `New` badge on a card (coarse, undocumented threshold),
3. the JD text when it names a date.

Write `Posted: Not specified` rather than guessing an age. Never fabricate "2h ago". If the `Date` filter cannot be applied, record the limitation and treat age as `unknown`.

## 6. Fallback results are not matches

When a query has no exact hits, Indeed silently appends recommendation blocks such as `Similar jobs` and fills the list with unrelated titles (searching `React Developer` can return AI/ML, security or product roles). Sponsored cards ignore every filter.

- Never trust the result list as evidence. Judge each posting from its own title, JD and fields.
- A card whose title is off-family is skipped before opening and counted, never added to the report.
- An ad card is usable only when its own detail page passes the same checks.

## 7. Application-process fields

Record while the job is open; these are informational and never affect match/review/excluded.

**Easy Apply (`easyApply`)** — `Yes` when the detail pane shows `Quick application` / `Schnellbewerbung` (an `a[href*="smartapply.indeed.com"]` link that applies inside Indeed). `No` when the only control is `Continue to the application` / `Auf der Unternehmensseite bewerben` (`/applystart?jk=...`, which redirects to the employer or ATS). `Unknown` when neither is visible.

**Apply type (`applyType`)** — `easy_apply` for the first case, `external` for the second, `unknown` otherwise.

**Cover letter** — `Yes` only when the page or JD explicitly requires one; `No` when explicitly optional or absent; `Unknown` when unstated.

**Quick application form** — open it once, read-only, record every visible field into `<run>/<Company>-<JobTitle>/fields.json`, close it. Never fill, upload or submit it; the row stays with the user.

**External form** — click `Continue to the application` once, record the ATS, host, final `applyUrl` and every field read-only. `job-apply` files it after the report; a blocker becomes `blocked: <reason>` in `fields.json` plus a row in `.opencode/skills/job-apply/help.md`.

## 8. Access boundaries

Indeed may return an empty page, a "No jobs were found" page containing only recommendations, a login wall, a `verify you are human` challenge or a rate limit after several queries.

**A trust or automation-suspicion dialog ends the whole run, not just this source.** That includes `verify you are human`, CAPTCHA, `unusual traffic` / `unusual activity`, `automated access`, `are you a robot`, an AI-agent warning, and a forced re-login or 2FA prompt. Stop immediately: no further navigation, no retry, no reload, no form filling, no Submit. Record the platform and the exact dialog text, keep what is already recorded, and tell the user to take over.

Only a plain "no results" page or a single failed page load is treated as a normal source boundary: then stop this source, record it in `limitations` and `searchedBySource`, and continue with the next source. Never solve a CAPTCHA, never create an account, never rotate sessions or proxies. Never save on Indeed unless `common.saveMatchedJobs` is `true` and the row is `matched` (§10).

Keep the query count low and do not reload pages in a loop; a burst of navigations is what triggers the degraded responses.

## 9. Known quirks

- Country is encoded in the domain; job IDs are not portable between domains.
- The same job appears as organic + sponsored + `Similar jobs` in one page — deduplicate by `jk`.
- Interface language follows the `lang` parameter and/or the account; a translation browser extension rewrites visible text, so read attributes (`data-jk`, `href`) and JD containers instead of trusting translated `innerText`.
- The result header may omit the total count. Use the browser tab title when it says "Find N open positions", otherwise record `null`; never estimate.
- Salary ranges, ratings and benefit tags are display data only and never filters.

## 10. Saving matched postings

Only when `common.saveMatchedJobs` is `true`, and only for a vacancy just classified `matched` (normal or confirmed agency/third-party). One save per vacancy, on the job detail pane, right after classification and **before** `Continue to the application` — that control leaves Indeed.

- The control is `Save job` / `Job speichern` in the detail pane (often `Gespeichert` / `Saved` when already saved). A saved state is never clicked; record `already saved`.
- Indeed usually requires a signed-in account to save. If `Save job` opens a sign-in prompt, closes without changing state, or is absent, record `not saved: login required` / `not saved: no save control`, close the prompt and continue. Never sign in or create an account to save.
- Click once only, verify the label changed to the saved state, and record `saved`. An unverified click becomes `not saved: control did not respond`.
- Never toggle a save off, never save a `review`, `excluded`, expired or skipped job, and never use a card-level save icon.
- Saving is unconditional: it does not depend on `applications.enabled`, a fillable form, a successful submission or the user applying later.
