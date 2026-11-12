# LinkedIn

Reference implementation for `sources: ["LinkedIn"]`. Follow this file for the search, filters and result extraction; the filtering and reporting rules stay in `SKILL.md`.

## 1. Search entry

Open LinkedIn Jobs and use its AI job search, entering `jobSearchPrompt` **verbatim**.

- Do not rewrite, split, translate or append cities.
- Submit once. Re-submitting a changed prompt invalidates the filters you already set.
- If the AI search is not available in the account's UI, fall back to the plain keyword search with the same prompt text and say so in `limitations`.

## 2. Filter mapping

Text inside `jobSearchPrompt` is not a filter: LinkedIn does not reliably enforce "24 hours", "full-time" or similar wording written in the prompt. Set the filters in LinkedIn's filter bar after submitting, and verify they show as active before reading results.

| Config | LinkedIn control | Mapping |
|---|---|---|
| `lookbackHours` | Date posted | ≤24 → `Past 24 hours`; ≤168 → `Past week`; ≤720 → `Past month`; larger → no date filter. Pick the closest bucket that **fully covers** the window, never a narrower one. |
| `employmentTypes` | Employment type | When it is a real subset, check exactly: `Full-time`, `Part-time`, `Contract`, `Temporary`, `Internship`, `Volunteer`. |
| `workModes` | Work mode / Remote | When it is a real subset of `Remote` / `Hybrid` / `On-site`, select the matching filter. |
| `seniority.include` | Experience level | Only when configured and the labels map unambiguously; otherwise skip the UI filter and judge on the page. |
| `countries`, `locations` | Location | Set the configured country; add cities only when `locations` is non-empty, and only if the location filter supports it. |

Do not add filters that are not in the config, such as salary, company, Easy Apply or applicant count. Use the visible controls; URL parameters like `f_TPR` and `f_JT` may be dropped by the AI search page, so do not rely on them.

If a filter cannot be applied, say so and read that field on each posting instead. Never assume the prompt filtered it.

## 3. Result extraction

- Job ID: the numeric ID in the card's link, e.g. `4487182341`.
- Canonical URL: `https://www.linkedin.com/jobs/view/<jobId>/`. Strip tracking parameters (`?trk=`, `?refId=`, `?trackingId=`, `?originalSubdomain=`).
- Company, title, location and posting age come from the card; the detail page wins on conflicts.
- Collect every card's canonical URL before opening details, then deduplicate.

## 4. Premium "You'd be a top applicant" prompt

Read this only when `linkedinPremium` is `true`. The account then shows a personal prompt on some jobs — **"You'd be a top applicant"**, **"You'd be a top applicant for this role"** or a **"Top applicant"** badge — on the result card and/or the detail page. Match it case-insensitively and accept both `'` and `’`; in a non-English UI, match its localized equivalent.

- Record it per vacancy for this run only (`topApplicant`, phrase verbatim, `card` / `detail`); do not persist it in the index. The detail page wins; a card-only prompt still counts.
- Never infer it from applicant counts, Easy Apply, search ranking or JD text. No visible prompt means no flag; `false` or absent skips this section without a limitation.
- It is ordering metadata, not a check. Classification is unchanged: a prompted job that fails any check (e.g. JD language) is excluded and stays out of the priority group.

## 5. Pagination

Advance with the results pagination control (or the next-page button). Stop when:

- the next page's postings are older than `lookbackHours`;
- LinkedIn reports no more results;
- the same postings repeat;
- a login wall, CAPTCHA or rate limit appears.

Record the displayed result count when the page shows one, plus the number of result pages actually opened and the stop reason.

## 6. Access boundaries

If LinkedIn requires login, shows a CAPTCHA, or blocks the run, stop this source and record it in `limitations`. Never ask for credentials, never bypass access controls, and never apply, message, save or follow anything.

## 7. Application-process fields

Record these while the job page is open. They are informational only and never affect match/review/excluded classification.

**Easy Apply:** `Yes` when the detail page shows an "Easy Apply" button that applies within LinkedIn; `No` when the apply button clearly redirects to the employer's site or an external application form; `Unknown` when neither is visible. Never infer it from applicant counts, Easy Apply badges on cards, or JD text.

**Cover letter:** `Yes` when the page or the Easy Apply flow explicitly states a cover letter is required; `No` when it explicitly states cover letter is optional or not needed; `Unknown` when neither is stated. Do not open the apply flow just to check — record only what is visible on the job page.

## 8. Known quirks

- The AI search page may reset filters after a new submission — re-apply and re-verify.
- The same role can appear under several job IDs, including multi-city and bilingual versions; that is handled by the soft-dedup rules in `job-index-and-audit.md`.
- `Easy Apply` is not a filter and must never be used as one.
