# LinkedIn post search

Reference for `linkedin-feed-jobs`. Every job title, location, hiring keyword and stack term comes from `job-hunter.config.json`. This file must never contain a hardcoded list of job titles, cities, regions or countries.

## 1. Entry

```
https://www.linkedin.com/search/results/content/?keywords=<query>&datePosted=<bucket>&sortBy=date_posted
```

- `keywords`: URL-encoded query.
- `datePosted`: `past-24h`, `past-week` or `past-month`.
- `sortBy=date_posted`.
- Open in the dedicated feed tab. Do not reuse the feed tab's scroll position.

After load, verify the page shows a date filter matching the bucket and `Sort by: Date posted`. If the URL parameters were dropped, set the same controls in the UI and verify again. If the controls are unavailable, record the limitation and fall back to the Recent feed pass.

## 2. Inputs from config

| Input | Config key | Use |
|---|---|---|
| Titles | `jobTitles.include` | Query terms and the hard title gate |
| Locations | `locations`, then `countries` | Query terms and the hard location gate |
| Extra location terms | `linkedinFeedJobs.locationTerms` | Appended only when non-empty |
| Hiring keywords | `linkedinFeedJobs.searchKeywords` | Query terms |
| Stack terms | `technicalKeywords.include` | Query terms and `Matched keywords` |
| Query cap | `linkedinFeedJobs.maxQueries` | Maximum queries per run |
| Page cap | `linkedinFeedJobs.maxPagesPerQuery` | Pages per query |

Read the values at run time. Never copy them into this file or into `SKILL.md`.

When `locations` is empty, the location terms are exactly the configured `countries` values. When `locations` is non-empty, use those values and do not add countries.

## 3. Query building

Normalize titles for query building only: lowercase, collapse whitespace, replace `-`/`_` with a space, fold joined and separated spellings, strip a leading seniority prefix, deduplicate. Never change the title used for matching.

Build in this order, stop at `maxQueries`:

1. **Title queries** — one per base title, up to 6: `<hiring keyword> "<base title>" <location term>`
2. **Stack queries** — one per location term, up to 4: `<hiring keyword> (<stack term> OR <stack term>) <location term>`
3. **Broad query** — one: `(<hiring keywords>) (<base titles>) (<location terms>)`

Rules:

- Quote multi-word titles. Keep each query under about 300 characters.
- Rotate location terms across queries; do not repeat the same term in every query.
- Use only configured hiring keywords, titles, stack terms and location terms.
- Never add a city, country, company, salary, seniority or easy-apply filter that is not in the config.
- Prefer plain keyword queries over boolean ones. If a boolean query returns zero cards or an error, retry it once without parentheses and `OR`.
- Use the local-language spelling of a configured location only when it denotes the same place as the configured value.

## 4. Time bucket

| `lookbackHours` | `datePosted` |
|---|---|
| ≤ 24 | `past-24h` |
| ≤ 168 | `past-week` |
| ≤ 720 | `past-month` |
| > 720 | omit the parameter |

Pick the closest bucket that fully covers the window, never a narrower one. Then filter each card by its relative time:

```js
const ageHours = (label) => {
  const m = (label || '').trim().match(/^(\d+)\s*([mhdw])$/i);
  if (!m) return null;
  const n = Number(m[1]);
  return { m: n / 60, h: n, d: n * 24, w: n * 168 }[m[2].toLowerCase()];
};
```

`1d` covers 24–48 hours. When `lookbackHours` is 24, include `1d` as the boundary and mark `24h boundary`.

## 5. Collect

Expand truncated posts first:

```js
const expand = async () => page.evaluate(() => {
  let n = 0;
  document.querySelectorAll('button').forEach(b => {
    const t = (b.innerText || '').trim();
    if (/^(…|...)\s*more$/i.test(t) || t.toLowerCase() === 'see more') {
      try { b.click(); n++; } catch (e) {}
    }
  });
  return n;
});
```

Collect cards from the results container. Cover both the search list and embedded feed cards:

```js
const collect = async () => page.evaluate(() => {
  const seen = new Set();
  const out = [];
  const nodes = document.querySelectorAll(
    'div[role="listitem"], div.feed-shared-update-v2, [data-urn*="urn:li:activity"]'
  );
  nodes.forEach(el => {
    const text = (el.innerText || '').trim();
    if (!text) return;
    const urn = el.getAttribute('data-urn') || el.getAttribute('componentkey') || '';
    const link = el.querySelector('a[href*="/feed/update/"], a[href*="urn:li:activity"]');
    const href = link ? link.href.split('?')[0] : '';
    const key = urn || href || text.slice(0, 120);
    if (seen.has(key)) return;
    seen.add(key);
    out.push({ key, text, href });
  });
  return out;
});
```

For each card record: text, author, relative time, permalink, hiring keywords seen, and the rendered location phrase if any. Deduplicate by activity URN, then by canonical permalink, then by the first 120 characters of text.

If the browser cannot expose `innerText` for a card, skip it and count it as unreadable; never guess its content.

## 6. Pagination

Advance with the results `Next` / `Show more results` control, otherwise scroll the results container (`.scaffold-finite-scroll__content`, then `#workspace`, then `window`).

Stop when any of these happens:

- `maxPagesPerQuery` pages are read;
- two consecutive screens add no new card;
- the next cards are older than `lookbackHours`;
- results repeat;
- a login wall, CAPTCHA or rate limit appears.

Keep a per-query count: pages opened, cards seen, new cards after dedupe, stop reason.

## 7. Permalink

1. Read the timestamp anchor's `href` when it matches `/feed/update/` or `urn:li:activity`; strip the query string.
2. Otherwise open the post's `Open control menu for post`, choose `Copy link to post`, and read the clipboard (`pbpaste` on macOS). Keep `https://lnkd.in/p/...` as-is.
3. Otherwise write `Link unavailable`.

Never assemble a URL from a URN, company name or title. Hide extension overlays before clicking a menu:

```js
await page.evaluate(() => {
  document.querySelectorAll('#interop-outlet, [data-testid="interop-shadowdom"]')
    .forEach(e => { e.style.display = 'none'; });
});
```

## 8. Recent feed supplement

When `linkedinFeedJobs.includeRecentFeed` is `true`, run one Recent-feed pass after the searches:

- Follow `.opencode/skills/linkedin-feed-review/references/feed-extraction.md` for opening, sorting, collecting and scrolling.
- Read at most `maxScreens` screens; stop after two screens with no post in the window.
- Do not apply `linkedinFeedReview.excludeTopics`; hiring posts are the target here.
- Merge results into the same dedupe set.

## 9. Limits and failures

- Never log in, solve a CAPTCHA or bypass an access control. Stop the affected query and record it in limitations.
- Stop the whole search after three consecutive blocked or empty queries and fall back to the Recent feed pass.
- Write large raw result sets to a temp file with `files.write` and read it in chunks.
- Search results are not proof a role is still open; validity is judged from the post text only.
