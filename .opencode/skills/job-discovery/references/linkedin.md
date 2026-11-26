# LinkedIn

Reference for `sources: ["LinkedIn"]`. Search, filters and result extraction live here; matching and reporting rules stay in `SKILL.md`.

## 1. Search entry

Open LinkedIn Jobs and submit **one query per `common.searchTitles` entry, in order, one at a time**.

- Use the search box (`Describe the job you want`) and type the configured title exactly. Never rewrite, split, translate, merge, shorten or extend it, and never append cities, stack words or a time range — the filters are set in the UI, not in the query.
- Submit one query, finish all its pages, then start the next. Re-submitting replaces the active filters, so re-apply and re-verify `Past 24 hours` + `Full-time` after every new query.
- Read the search box back: LinkedIn appends `full-time posted in the past 24 hours`; that suffix is UI-added and acceptable. If the title itself differs, clear the box and resubmit.
- Set `queryVerbatim: true` in the audit only after that comparison passed, and name the titles actually submitted.
- Fallback when the search box is unavailable: `https://www.linkedin.com/jobs/search-results/?keywords=<title>&f_TPR=r86400&f_SAL=f_SA_id_226001%3A272015&start=<n>` yields the same filtered list. Load it **in the existing working tab**, never in a new tab; do not try the legacy `/jobs/search/` URL. Say so in `limitations` and keep the title exactly as configured.

## 2. Filter mapping

Text inside the query is not a filter. Set the filters in the filter bar after submitting and verify they are active before reading results.

| Config | LinkedIn control | Mapping |
|---|---|---|
| `common.lookbackHours` | Date posted | ≤24 → `Past 24 hours`; ≤168 → `Past week`; ≤720 → `Past month`; larger → no date filter. Closest bucket that **fully covers** the window. |
| `common.employmentTypes` | Employment type | When a real subset, check exactly: `Full-time`, `Part-time`, `Contract`, `Temporary`, `Internship`, `Volunteer`. |
| `common.workModes` | Work mode | When a real subset of `Remote` / `Hybrid` / `On-site`, select the matching filter. |
| `common.seniority.include` | Experience level | Only when configured and labels map unambiguously; otherwise judge on the page. |
| `common.countries`, `common.locations` | Location | Set the configured country; add cities only when `locations` is non-empty and the control supports it. |

Do not add filters that are not in the config (salary, company, Easy Apply, applicant count).

**Gate before reading any card.** `Past 24 hours` and `Full-time` must both render as active filter pills — not suggested chips. If either is missing, set it again and re-verify. If a filter genuinely cannot be applied, stop this source instead of reading unfiltered results.

## 3. Result extraction

Step 1 reads cards only; it never opens a posting.

- Job ID: numeric ID in the card link, e.g. `4487182341`. The current UI carries `componentkey="job-card-component-ref-<jobId>"` on the card element.
- Canonical URL: `https://www.linkedin.com/jobs/view/<jobId>/`. Strip `?trk=`, `?refId=`, `?trackingId=`, `?originalSubdomain=`.
- Company, title, location and posting age come from the card; the detail page wins on conflicts in step 3.
- Record per card: company, published title, canonical URL, job ID, source, and which search title returned it.
- Deduplicate by job ID / canonical URL across all titles before counting.

## 4. Premium "You'd be a top applicant" marker

Read this only when `platforms.LinkedIn.premium` is `true`. Some jobs show **"You'd be a top applicant"**, **"You'd be a top applicant for this role"** or a **"Top applicant"** badge on the card and/or detail page. Match case-insensitively, accept `'` and `’`, and use the localized equivalent in a non-English UI.

- Record it per vacancy for this run only (`topApplicant`, `card` / `detail`); do not persist it in the index. The detail page wins.
- Never infer it from applicant counts, Easy Apply, ranking or JD text. No visible marker means no flag.
- It is ordering metadata, never a check: a top-applicant job that fails any check is still excluded.

## 5. Pagination

The list holds 25 cards per page. Advance with the page control, `Next`, or `start=25`, `start=50`, … Stop when:

- the page returns fewer than 25 cards (last page);
- LinkedIn reports no more results;
- the same postings repeat;
- `platforms.LinkedIn.search.maxPagesPerQuery` is reached;
- a login wall, CAPTCHA or rate limit appears.

Record the displayed result count when shown, plus pages opened and the stop reason.

## 6. Access boundaries

If LinkedIn requires login, shows a CAPTCHA or blocks the run, stop the entire run and record it in `limitations`. Never ask for credentials and never bypass access controls. Never message, follow or change account settings. Never save a job on LinkedIn unless `common.saveMatchedJobs` is `true` and the row is `matched` (§9); never save from a login wall. Opening an employer form read-only is allowed; never fill, upload or submit it.

**A trust or automation-suspicion signal on LinkedIn stops everything.** `verify you are human`, CAPTCHA, `unusual activity` / `unusual traffic`, `automated access`, `are you a robot`, an AI-agent warning, or a forced re-login/2FA mid-run: stop the whole run immediately — no navigation, retry, refresh, filling or Submit. Record the exact dialog text and tell the user to take over. The same signal on an employer/ATS page opened from LinkedIn is handled by `job-apply`: close only that third-party tab, record the blocker, and continue.

## 7. Application-process fields

Record these while the job page is open; they never affect classification.

**Easy Apply:** `Yes` when the detail page shows an "Easy Apply" button that applies inside LinkedIn; `No` when the button redirects to the employer or an external form; `Unknown` when neither is visible. Never infer it from cards, applicant counts or JD text.

**Apply type:** `easy_apply` / `external` / `unknown` from the same button.

**Easy Apply form:** open the modal once, read-only, record every visible field into `<run>/<Company>-<JobTitle>/fields.json`, close it. Never fill, upload or submit.

**External form:** click Apply once, confirm the destination is not `linkedin.com`, then inspect read-only: ATS, host, final `applyUrl`, blockers and every field. `job-apply` files it after the report; a blocker becomes `blocked: <reason>` in `fields.json` plus one entry in `.opencode/skills/job-apply/help.json`. Draft the cover letter when the form asks for one.

**Cover letter:** `Yes` when required, `No` when explicitly optional or absent, `Unknown` when unstated. The form's field is authoritative; a page-only mention is a hint.

## 8. Known quirks

- Filters live in the URL (`f_TPR=r86400`, `f_SAL=f_SA_id_226001%3A272015`) and reset after a new query submission — re-apply and re-verify both pills.
- The left list holds 25 cards per page; scrolling alone never loads more. Use the page control, `Next` or `start=`.
- The search box is rewritten on submit (LinkedIn appends `full-time posted in the past 24 hours`); compare only the title part.
- The same role can appear under several job IDs (multi-city, bilingual); handle it with the soft-dedup rules in `job-index-and-audit.md`.
- `Easy Apply` is not a filter and must never be used as one.

## 9. Saving matched postings

Only when `common.saveMatchedJobs` is `true`, and only for a vacancy the run has just classified `matched` (normal or confirmed agency/third-party). One save per vacancy, on the job detail page, right after classification and **before** clicking Apply — an external Apply leaves the page.

- The control sits in the top card of the job detail page: a `Save` button (`aria-label` like `Save the job`, `Save <job title>`) or `Save` inside the `…` overflow menu. Localized labels: `Speichern`, `Gespeichert`, `收藏`, `已收藏`.
- The card state is authoritative: `Save` = not saved, `Saved` / filled bookmark = already saved. A job already in `Saved` state is never clicked and is recorded as `already saved`.
- Click once, then verify the label changed to `Saved` / `Gespeichert` (or the bookmark is filled). Record `saved` only after that verification; otherwise record `not saved: control did not respond`.
- Never use the Save icon on a result card or in a list, never save a `review`, `excluded`, expired or skipped job, and never click Save twice or toggle a save off.
- No Save control visible, or a sign-in prompt in its place → record `not saved: no save control` / `not saved: login required`, continue the row. Never sign in or create an account to save.
- Saving is unconditional: it does not depend on `applications.enabled`, a fillable form, a successful submission or the user applying later.
