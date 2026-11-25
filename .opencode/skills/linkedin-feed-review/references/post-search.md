# LinkedIn post search

Reference for `linkedin-feed-review`. It searches LinkedIn **posts by topic**; it
never reads the user's home feed. Every query term comes from
`job-hunter.config.json`. This file must never contain a hardcoded list of
topics, job titles, cities or countries.

## 1. Entry

```
https://www.linkedin.com/search/results/content/?keywords=<query>&datePosted=<bucket>&sortBy=date_posted
```

- `keywords`: URL-encoded query from `platforms.LinkedIn.feedReview.searchTopics`.
- `datePosted`: `past-24h`, `past-week` or `past-month`.
- `sortBy`: `date_posted`.
- Open each query in the dedicated feed tab. Do not reuse the home-feed scroll
  position and never open `https://www.linkedin.com/feed/`.

After load, verify the page shows the matching date filter and
`Sort by: Date posted`. If the URL parameters were dropped, set the same controls
in the UI and verify again. If the controls are unavailable, record the
limitation and keep the cards the page did render.

## 2. Inputs from config

| Input | Config key | Use |
|---|---|---|
| Topics | `platforms.LinkedIn.feedReview.searchTopics` | Query text |
| Query cap | `platforms.LinkedIn.feedReview.maxQueries` | Maximum queries per run |
| Page cap | `platforms.LinkedIn.feedReview.maxPagesPerQuery` | Pages per query |
| Window | `platforms.LinkedIn.feedReview.lookbackHours`, else `common.lookbackHours` | `datePosted` bucket and per-card age |
| Germany scope | `common.locations`, then `common.countries` | Germany-relevance gate |
| Stack fallback | `common.technicalKeywords.include` | Query terms only when `searchTopics` is empty |

Read the values at run time. Never copy them into this file or into `SKILL.md`.

## 3. Query building

Run one query per `searchTopics` entry, in order, up to `maxQueries`.
Deduplicate case-insensitively. Do not append hiring keywords: this skill looks
for discussion posts, not vacancies.

When `searchTopics` is empty, build up to `maxQueries` queries from
`common.technicalKeywords.include` plus the configured location/country terms
(for example `<stack term> <location term>`). If both lists are empty, stop and
ask.

Rules:

- Quote multi-word phrases when the query otherwise returns unrelated posts.
- Keep each query under about 300 characters.
- Use only configured topics, stack terms and location terms.
- Never add a company, salary, seniority or easy-apply filter that is not in the
  config.
- Rotate location terms across queries; do not repeat the same term in every
  query.
- Prefer plain keyword queries over boolean ones. If a boolean query returns zero
  cards or an error, retry it once without parentheses and `OR`.

## 4. Time bucket

| Window (`feedReview.lookbackHours`, else `common.lookbackHours`) | `datePosted` |
|---|---|
| ≤ 24 | `past-24h` |
| ≤ 168 | `past-week` |
| ≤ 720 | `past-month` |
| > 720 | omit the parameter |

Pick the closest bucket that fully covers the window, never a narrower one. Then
filter each card by its relative time:

```js
const ageHours = (label) => {
  const m = (label || '').trim().match(/^(\d+)\s*([mhdw])$/i);
  if (!m) return null;
  const n = Number(m[1]);
  return { m: n / 60, h: n, d: n * 24, w: n * 168 }[m[2].toLowerCase()];
};
```

`1d` covers 24–48 hours. When the window is 24 hours, include `1d` as the
boundary and mark `24h boundary`.

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

Collect cards from the results container. Cover both the search list and embedded
feed cards:

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

For each card record: text, author, headline, relative time, permalink and the
rendered location phrase if any. Deduplicate by activity URN, then by canonical
permalink, then by the first 120 characters of text. Merge duplicates across
queries.

If the browser cannot expose `innerText` for a card, skip it and count it as
unreadable; never guess its content.

## 6. Pagination

Advance with the results `Next` / `Show more results` control, otherwise scroll
the results container (`.scaffold-finite-scroll__content`, then `#workspace`,
then `window`).

Stop a query when any of these happens:

- `maxPagesPerQuery` pages are read;
- two consecutive screens add no new card;
- the next cards are older than the window;
- results repeat;
- a login wall, CAPTCHA or rate limit appears.

Keep a per-query count: pages opened, cards seen, new cards after dedupe, stop
reason.

## 7. Permalink

1. Read the timestamp anchor's `href` when it matches `/feed/update/` or
   `urn:li:activity`; strip the query string.
2. Otherwise open the post's `Open control menu for post`, choose
   `Copy link to post`, and read the clipboard (`pbpaste` on macOS). Keep
   `https://lnkd.in/p/...` as-is.
3. Otherwise write `Link unavailable`.

Never assemble a URL from a URN, company name or title. Hide extension overlays
before clicking a menu:

```js
await page.evaluate(() => {
  document.querySelectorAll('#interop-outlet, [data-testid="interop-shadowdom"]')
    .forEach(e => { e.style.display = 'none'; });
});
```

## 8. Limits and failures

- Never log in, solve a CAPTCHA or bypass an access control. Stop the affected
  query and record it in limitations.
- Stop the whole search after three consecutive blocked or empty queries.
- Write large raw result sets to a temp file with `files.write` and read it in
  chunks.
- Search results are not proof a post is still public; judge only the rendered
  text.
- Do not open profiles for discovery. Open a candidate author's profile once,
  read-only, only when the post itself does not establish the Germany context.
