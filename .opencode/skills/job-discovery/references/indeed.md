# Indeed

Reference for `sources: ["Indeed"]` (any country domain, e.g. `de.indeed.com`, `indeed.com`).

The UI varies by country and changes often. Confirm a control exists in the live page before relying on it; if a control is missing, use the stated fallback instead of inventing one.

## 1. Search entry

Open the Indeed jobs page for the country that matches `countries` and submit `jobSearchPrompt` **verbatim** in the keyword field. Set the location field from `countries`/`locations` only when the site provides one; otherwise let the search run and rely on the page location when judging scope.

- Prefer the visible search form. URL parameters may be used to seed the same search, but only with the unmodified prompt text: `q=<prompt>` and `l=<location>`.
- Do not translate, shorten or split the prompt.

## 2. Filter mapping

| Config | Indeed control | Mapping |
|---|---|---|
| `lookbackHours` | Date posted | ≤24 → `Last 24 hours`; ≤72 → `Last 3 days`; ≤168 → `Last 7 days`; ≤336 → `Last 14 days`; otherwise `Last 30 days` or no filter. Never choose a window narrower than `lookbackHours`. |
| `employmentTypes` | Job type | `Full-time`, `Part-time`, `Contract`, `Temporary`, `Internship`. Indeed has no reliable `Volunteer` equivalent — skip that value and judge on the page. |
| `workModes` | Remote | Indeed exposes a `Remote` filter. `Hybrid` and `On-site` usually have no filter: select nothing for them and judge on the page. |
| `seniority.include` | — | No equivalent. Skip the UI filter and judge from the title or explicit level wording. |
| `countries`, `locations` | Where | Country comes from the domain; put configured cities in the location field. With no `locations`, leave it at country level. |

Do not add filters that are not in the config (salary estimate, company rating, `Easy apply`, urgency). Indeed sometimes carries a URL form of the same filters (`fromage`, `jt`, `sc`); they are acceptable shortcuts only after confirming the page shows the same selection.

Verify the applied filters are visible on the results page. If Indeed drops them, apply them again or fall back to reading each posting.

## 3. Result extraction

- Job key: the `jk` parameter on the card link or apply button, e.g. `jk=7f3c9a1b2d4e5f60` (usually 16 hex characters). A card without `jk` is not usable — skip it and count it as a card skip.
- Canonical URL: `https://<country-domain>/viewjob?jk=<jk>`. Strip tracking parameters (`?vjs=`, `?tk=`, `?from=`, `?advn=`, `?xpse=`, `?xkcb=`); keep `jk`.
- Company and location come from the card; the detail page wins on conflicts.
- Indeed shows sponsored cards that repeat organic results — deduplicate by `jk` before opening.

## 4. Pagination

Advance with the results pagination control (or `start=10`, `start=20`, … if the page exposes it). Stop when:

- postings are older than `lookbackHours`;
- the page shows no further results;
- the same `jk` set repeats;
- a login wall, CAPTCHA or rate limit appears.

## 5. Access boundaries

Indeed may interrupt with a login prompt, a "verify you are human" challenge or a rate limit after several pages. Stop this source at that boundary, record it in `limitations`, and continue with other sources. Never solve a CAPTCHA, never create an account, never use the "Easy apply" flow.

## 6. Application-process fields

Record these while the job page is open. They are informational only and never affect match/review/excluded classification.

**Easy Apply:** `Yes` when the detail page shows an "Indeed Apply" or "Easy Apply" button that applies within Indeed; `No` when the apply button clearly redirects to the employer's site or an external application form; `Unknown` when neither is visible. Never infer it from badges or search ranking. Never use the "Easy apply" flow itself.

**Cover letter:** `Yes` when the page or the application form explicitly states a cover letter is required; `No` when it explicitly states cover letter is optional or not needed; `Unknown` when neither is stated. Do not open the apply flow just to check — record only what is visible on the job page.

## 7. Known quirks

- Country is encoded in the domain: use `de.indeed.com` for Germany, and so on. Search results and job IDs are not portable across domains.
- Sponsored and organic cards duplicate each other; deduplicate on `jk`.
- The job page URL form differs from the card link; always normalise to `/viewjob?jk=<jk>`.
- Salary and company-rating badges are not filters and must not influence classification.
