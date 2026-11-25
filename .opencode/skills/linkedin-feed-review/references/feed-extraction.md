# LinkedIn Recent feed extraction

Use this recipe only for the `linkedin-feed-jobs` Recent-feed supplement.
`linkedin-feed-review` does not read the home feed; it uses
`post-search.md` instead. This file matches the current LinkedIn feed DOM.

## 1. Open and sort

```js
await page.goto('https://www.linkedin.com/feed/', { waitUntil: 'domcontentloaded' });
await page.waitForTimeout(5000);

const sortBtn = page.locator('div[role="button"]').filter({ hasText: 'Sort by:' }).first();
await sortBtn.click();
await page.waitForTimeout(1200);
await page.getByText('Recent', { exact: true }).last().click();
await page.waitForTimeout(4000);
```

Verify the label says `Sort by: Recent`. If not, retry once.

## 2. Collect

Posts are `div[role="listitem"]` elements whose `componentkey` contains `update-card`. Do not read `div[role="list"]` direct children.

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

const collect = async () => page.evaluate(() =>
  Array.from(document.querySelectorAll('div[role="listitem"][componentkey*="update-card"]'))
    .map(e => ({ key: e.getAttribute('componentkey') || '', text: (e.innerText || '').trim() }))
);

const scroll = async () => page.evaluate(() => {
  const m = document.getElementById('workspace');
  if (m) { m.scrollBy(0, m.clientHeight * 0.9); return m.scrollTop; }
  window.scrollBy(0, 800);
  return window.scrollY;
});
```

Expand, collect, deduplicate by `componentkey`, scroll. Read at most 10 screens; stop after three screens with no post in the window. Write large results to a temp file with `files.write` and read it in chunks.

## 3. Hide click blockers

Hide extension overlays before clicking a post menu:

```js
await page.evaluate(() => {
  document.querySelectorAll('#interop-outlet, [data-testid="interop-shadowdom"]')
    .forEach(e => { e.style.display = 'none'; });
});
```

## 4. Copy a permalink

Do this only for selected posts.

1. Find the post by a unique text fragment.
2. Click `button[aria-label^="Open control menu for post"]`.
3. Click `Copy link to post` in the visible `[role="menu"]`.
4. Read the clipboard (`pbpaste` on macOS). If unavailable, write `Link unavailable`.

```js
const key = await page.evaluate((marker) => {
  const el = Array.from(document.querySelectorAll('div[role="listitem"][componentkey*="update-card"]'))
    .find(e => (e.innerText || '').includes(marker));
  if (!el) return null;
  el.scrollIntoView({ block: 'center' });
  return el.getAttribute('componentkey');
}, 'unique text fragment');

await page.locator(`[componentkey="${key}"] button[aria-label^="Open control menu for post"]`).first().click();
await page.waitForTimeout(900);
await page.locator('[role="menu"]').filter({ hasText: 'Copy link to post' }).last()
  .getByText('Copy link to post', { exact: true }).click();
```

The copied URL is usually `https://lnkd.in/p/...`. Keep it as-is.

## 5. Time window

LinkedIn shows `23h` then `1d`. `1d` covers 24–48 hours. With `common.lookbackHours` 24, include `1d` as the boundary and mark `24h boundary`.

## 6. Avoid

- Reading `div[role="list"] > *`.
- Scrolling `window` when `#workspace` exists.
- Re-navigating between screens.
- Opening profiles for discovery. Open a candidate profile once, read-only, only to confirm role and location.
- Clicking links inside posts.
