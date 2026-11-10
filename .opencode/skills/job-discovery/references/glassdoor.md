# Glassdoor

Reference for `sources: ["Glassdoor"]`, using the German site `https://www.glassdoor.de` when the configured country is Germany. Use the matching country domain otherwise (for example `glassdoor.com`, `glassdoor.co.uk`).

Glassdoor changes its job-search markup frequently and sometimes gates results. Confirm each control in the live page; when a control is missing, use the stated fallback.

## 1. Search entry

Open `https://www.glassdoor.de/Job/jobs.htm` and submit `jobSearchPrompt` **verbatim** in the keyword field (`sc.keyword`). Use the location control for `countries`/`locations`.

- Do not translate or shorten the prompt.
- If the modern search page uses a different path, follow the visible "Jobs" navigation rather than guessing a URL.
- Signed-out visitors may be shown a subset of results or a sign-in prompt; treat that as an access boundary (section 5), not as an empty result.

## 2. Filter mapping

| Config | Glassdoor control | Mapping |
|---|---|---|
| `lookbackHours` | Date posted | ≤24 → `Last 24 hours`; ≤72 → `Last 3 days`; ≤168 → `Last 7 days`; ≤336 → `Last 14 days`; otherwise `Last 30 days` or no filter. Never narrower than `lookbackHours`. |
| `employmentTypes` | Job type | `Full-time`, `Part-time`, `Contract`, `Temporary`, `Internship`. No reliable `Volunteer` equivalent — judge on the page. |
| `workModes` | Remote | Glassdoor exposes a `Remote` filter in some markets. `Hybrid` / `On-site` usually have none: select nothing and judge on the page. |
| `seniority.include` | — | No equivalent. Judge from the title or explicit level wording. |
| `countries`, `locations` | Location | Country comes from the domain; configured cities go into the location field. With no `locations`, keep country level. |

Do not add filters that are not in the config (company rating, salary, industry, company size). Glassdoor's rating and salary widgets are not matching dimensions.

Verify the filters are visibly applied. If Glassdoor resets them, re-apply or fall back to reading each posting.

## 3. Result extraction

- Job listing ID: the `jobListingId` query parameter, or the `JV_...` / `KO...KE...` segment in the listing URL.
- Canonical URL: the listing URL that contains `jobListingId`, with tracking parameters removed (keep the listing ID and job title slug).
- Company, title, location and posting age come from the card; the detail page wins on conflicts.
- Glassdoor often redirects to the employer's own career site. Keep the Glassdoor listing URL as the canonical link, and record the employer URL in the note only when it is visible on the page.

## 4. Pagination

Advance with the results pagination control (`p=2`, `p=3`, …) or infinite scroll, whichever the page uses. Stop when:

- postings are older than `lookbackHours`;
- no further results load;
- the same listing IDs repeat;
- a sign-in prompt, CAPTCHA or rate limit appears.

## 5. Access boundaries

Glassdoor gates some listings and some pages behind sign-in. When that happens:

1. Stop this source; do not attempt to work around the gate.
2. Record it in `limitations` as `glassdoor: sign-in required`.
3. Continue with the remaining sources.

Never solve a CAPTCHA, never create an account, and never submit an application or "easy apply".

## 6. Known quirks

- `glassdoor.de` serves German UI and German-language listings; a listing's own language may still be English. Judge the JD language from the posting, never from the site locale.
- Ratings, salary estimates and "best places to work" badges are not filters and must not influence classification.
- Some listings are aggregator copies of other boards; the same role may appear on LinkedIn or Indeed with a different ID — soft dedup will flag it.
- Redirects to employer career sites can lose the original posting date; when the Glassdoor card shows a date, use it.
