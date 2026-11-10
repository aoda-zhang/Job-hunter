# <Platform>

Reference for `sources: ["<Platform>"]`. File name is the platform name lowercased (`Indeed` → `indeed.md`); a configured country domain such as `glassdoor.de` resolves to `glassdoor.md`.

Replace every `<...>` placeholder and delete the guidance sentences before committing. A reference is complete only when it answers the seven points below; if the platform cannot answer one, say so and describe the fallback.

After adding the file, add the platform to the lookup table in `SKILL.md`.

## 1. Search entry

- URL or navigation path:
- Country domains, if the platform is split by country:
- Does the site accept `jobSearchPrompt` verbatim, or only keywords?
- Does it require sign-in before showing results?

## 2. Filter mapping

| Config | Platform control | Mapping |
|---|---|---|
| `lookbackHours` | Date posted | Exact labels and buckets, always the closest bucket that fully covers the window. |
| `employmentTypes` | Job type | Exact labels; list values that have no equivalent. |
| `workModes` | Remote / hybrid / on-site | Exact labels; if a mode has no filter, judge on the page. |
| `seniority.include` | Experience level | Exact labels; otherwise judge on the page. |
| `countries`, `locations` | Location | Country and city behaviour, including what happens when `locations` is empty. |

List any filter that must not be used even if the platform offers it.

## 3. Result extraction

- Job ID: where it lives in the URL or card.
- Canonical URL: the exact pattern, plus the tracking parameters to strip.
- Card fields to trust, and where the detail page wins.
- How duplicates appear in this platform's result list.

## 4. Pagination

- How to advance:
- When results are known to be older than `lookbackHours`:
- Signals that the list ended:
- How to read the displayed result count, if any.

## 5. Access boundaries

- What login, CAPTCHA, paywall or rate limit looks like here:
- Which of them stop the source:
- What to write in `limitations`:

## 6. Known quirks

- UI changes, URL forms, redirects, locale pitfalls, duplicated listings, anything that silently breaks a run.
