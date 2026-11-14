---
name: linkedin-feed-jobs
description: Read the LinkedIn Recent feed, add hiring posts whose title and stated location match job-hunter.config.json to today's daily report under Feed-sourced jobs, and ignore all non-matching posts. Read-only.
---

# LinkedIn Feed Jobs

Read the Recent feed, match hiring posts against the config, add matches to today's daily report. Never apply, message, like, comment, react, repost, follow or connect.

## 1. Read config

Read `job-hunter.config.json`:

- `countries`, `locations` — location gate.
- `jobTitles.include` — role gate.
- `technicalKeywords.include`, `.matchMode` — stack gate when the post names a stack.
- `workModes`, `employmentTypes`, `seniority.include` — reject only when the config restricts them and the post states a conflicting value.
- `jdLanguages.include`, `.acceptGermanJdWithEnglishWorkingLanguage` — language gate for a full JD.
- `excludeRecruiters` — skip staffing agencies and "our client" posts when `true`.
- `lookbackHours`, `preferredReportLanguage`, `reportRepo`.

If `jobTitles.include` or `countries` is empty, stop and ask.

## 2. Read the feed

Reuse the post set from `linkedin-feed-review` when both run in the same pass. Otherwise follow `.opencode/skills/linkedin-feed-review/references/feed-extraction.md`: open `https://www.linkedin.com/feed/`, set `Sort by: Recent`, read `div[role="listitem"][componentkey*="update-card"]` while scrolling `#workspace`. Do not re-navigate between screens.

A hiring post says "we're hiring", "open role", "looking for a [title]", "join my team", "DM me" or similar, and names a specific role. A generic "we're hiring engineers" is not enough.

## 3. Match

Job title and location are mandatory. Every other configured dimension is a confirmed-mismatch gate: skip when the post states a conflicting value, keep when it is unstated.

| Dimension | Rule |
|---|---|
| Job title | Must name a `jobTitles.include` title, a clear variant or a synonym. |
| Location | Require a stated city, country or remote scope inside `countries`. With `locations` set, require a listed city. With `locations` empty, accept any city in the country or a country-level post. |
| Technical keywords | If the post names a stack, require `matchMode` (`any` = one term, `all` = every term). If no stack, keep and note `stack not stated`. |
| Work mode | If `workModes` is a real subset and the stated mode is outside it, skip. If unstated, keep and note `mode not specified`. |
| Employment type | If `employmentTypes` is a real subset and the stated type differs, skip. If unstated, note `employment not specified`. |
| Seniority | If `seniority.include` is a real subset and the stated level differs, skip. |
| Direct employer | Skip a confirmed agency, third-party recruiter or "our client" post when `excludeRecruiters` is `true`. If unclear, keep and note `poster type unclear`. |
| JD language | Skip a full JD outside `jdLanguages.include` unless `acceptGermanJdWithEnglishWorkingLanguage` is `true` and the JD names English as the working language. A short post is not a full JD. |
| Validity | Skip a post that says the role is filled or closed. |

If the post states no location or no specific role, skip. Never infer a location from the author's profile or the company's headquarters.

## 4. Deduplicate

Read today's report, the previous 7 daily reports and `reports/job-index.json` before adding a row.

Skip when:

- the normalized company + title + location already appears in today's report;
- the job has `appliedOn` set in the index;
- the job is already `matched` or `review` in the index;
- two feed posts describe the same job; keep the newer or more specific one.

Normalize: lowercase, strip punctuation, `(m/w/d)`, `(all genders)`, and legal suffixes such as GmbH, AG, SE, Inc, Ltd, LLC. Never merge different cities.

## 5. Add to the daily report

Edit `reports/daily/YYYY-MM-DD.md`.

- Place a translated `## Feed-sourced jobs` section after matched jobs and before review and excluded.
- If the report is missing, create it with the report title and this section; note that the regular job-discovery run has not written its sections.
- Merge new rows; never duplicate a row or overwrite a user-edited row.
- If a run summary table exists, set its `Feed-sourced jobs` row to the row count. Do not create a run summary table.
- List only matches. Never list non-matching hiring posts or non-hiring posts anywhere, including the excluded table.
- If nothing matches, do not add the section.

Use these columns:

```markdown
| # | Source | Company | Title | Location | Mode | Posted | Matched keywords | Notes | Link |
|---|---|---|---|---|---|---|---|---|---|
| 1 | LinkedIn Feed | Example GmbH | Senior Frontend Engineer | Berlin | Hybrid | 2h ago | React, TypeScript | 来自 feed; hiring manager post | [Open](URL) |
```

- `Source`: `LinkedIn Feed`.
- `Company`: the company named in the post. Never guess.
- `Title`: the role as written.
- `Location`: the location as written. Never infer.
- `Mode`: the stated mode, or `Not specified`.
- `Posted`: the relative time (`2h ago`, `1 day ago`).
- `Matched keywords`: configured terms named in the post; `None matched` when a stack is named but no term matches; `Not stated` when no stack is named.
- `Notes`: start with `来自 feed` (`From feed` for non-Chinese reports), then one verifiable fact such as `hiring manager post`, `DM to apply`, `link in comments`. Add `stack not stated`, `mode not specified`, `employment not specified`, `level not specified` or `poster type unclear` when relevant.
- `Link`: the copied permalink; `Link unavailable` when none exists. Never assemble a URL.

Renumber `#` after merging.

## 6. Publish

If `reportRepo` is set, clone/pull it, copy the daily report to `reports/daily/YYYY-MM-DD.md`, merge the `Feed-sourced jobs` section into an existing remote file, commit `docs: add feed-sourced jobs for YYYY-MM-DD`, push and verify. On failure, report it and keep the local file. Never force-push. Publish nothing else.

## 7. Finish

Report hiring posts seen, rows added, skipped for missing title or location, skipped as duplicate or applied, the daily report path, publish status and limitations. Count only posts actually rendered.
