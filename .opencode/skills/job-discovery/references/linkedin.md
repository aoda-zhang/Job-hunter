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

## 4. Pagination

Advance with the results pagination control (or the next-page button). Stop when:

- the next page's postings are older than `lookbackHours`;
- LinkedIn reports no more results;
- the same postings repeat;
- a login wall, CAPTCHA or rate limit appears.

Record the displayed result count when the page shows one, plus the number of result pages actually opened and the stop reason.

## 5. Access boundaries

If LinkedIn requires login, shows a CAPTCHA, or blocks the run, stop this source and record it in `limitations`. Never ask for credentials, never bypass access controls, and never apply, message, save or follow anything.

## 6. Known quirks

- The AI search page may reset filters after a new submission — re-apply and re-verify.
- The same role can appear under several job IDs, including multi-city and bilingual versions; that is handled by the soft-dedup rules in `job-index-and-audit.md`.
- `Easy Apply` is not a filter and must never be used as one.
