---
name: linkedin-feed-jobs
description: During the daily LinkedIn feed pass that runs with the job search, detect hiring posts whose role and location match job-hunter.config.json, and add only the matching ones to today's daily report in a dedicated Feed-sourced jobs section. The author does not need to be followed. Non-matching posts are ignored completely and never enter the excluded table. Never applies, messages or interacts.
---

# LinkedIn Feed Jobs

Use this skill as part of the daily job search, after `job-discovery`, or whenever the user asks for feed-sourced jobs. It can reuse posts already collected by `linkedin-feed-review`, or run its own read-only Recent feed pass. The author does not need to be in the user's following list.

This skill never applies for a job, never messages the poster, and never likes, comments, reacts, reposts, follows or connects. It only reads the feed and writes the daily report.

## 1. Read the root configuration

Read `job-hunter.config.json`:

- `countries` and `locations` — location gate.
- `jobTitles.include` — role gate.
- `technicalKeywords.include` and `technicalKeywords.matchMode` — stack information when the post names technologies; never a gate.
- `workModes`, `employmentTypes`, `seniority.include` — informational when the post states them; never gates.
- `excludeRecruiters` — when `true`, skip staffing agencies and "our client" posts.
- `lookbackHours` — reuse the same window as the feed review.
- `preferredReportLanguage` — report language.
- `reportRepo` — publish the updated daily report after writing it.

If `jobTitles.include` or `countries` is empty, stop and ask the user; do not guess.

## 2. Read the feed posts

Do not browse the feed twice. If `linkedin-feed-review` already collected the Recent feed in this run, reuse the complete post set, including authors who are not on the following list. Otherwise open `https://www.linkedin.com/feed/`, set **Sort by: Recent**, and collect the posts.

The following list is irrelevant here: include hiring posts from any author, whether or not the user follows them. A job can still be worth applying to when the poster is a stranger, a 2nd/3rd-degree contact or a company page. Do not open author profiles and do not click external links.

A post is a **hiring post** when it explicitly says something like:

- "we're hiring", "I'm hiring", "join my team", "my team is growing";
- "open role", "job opening", "looking for a [title]", "hiring a [title]";
- "DM me", "apply here", "link in comments" together with a specific role.

The post must name a specific role from `jobTitles.include` or a clear synonym. A generic "we're hiring engineers" with no title is not enough.

## 3. Match the post against the config

**Only job title and location are mandatory.** A post that names a matching role and a matching location is enough, even if it mentions nothing else. Every other dimension is informational: record it when stated, never use it to drop the post, and note any conflict in the row. The following list is never a gate; only the root config decides whether a post matches.

| Dimension | Rule |
|---|---|
| Job title | Mandatory. The post must name one of `jobTitles.include`, a clear title variant or a synonym. |
| Location | Mandatory. The post must state a city, country or remote scope. With `locations` configured, the stated city must be one of them; a country-only post is not enough. With `locations` empty, a country-level post is enough. |
| Technical keywords | Informational. Record the configured terms that appear. If the post names a different stack, keep the row and note `stack: <terms>`; never drop it. |
| Work mode | Informational. Put the stated mode in the Mode column even if it is outside `workModes`; add `mode not in config` to Notes. If not stated, write `Not specified`. |
| Employment type | Informational. If stated, note it in Notes; never drop the post. |
| Seniority | Informational. If stated, note it in Notes; never drop the post. |
| Direct employer | Confirmed staffing agency, third-party recruiter or "our client" post: skip when `excludeRecruiters` is `true`. If the poster type is unclear, keep the row and note `poster type unclear`. |
| JD language | Informational. Note a full JD in an excluded language; never drop a title + location match. |
| Validity | Skip posts that explicitly say the role is filled or closed. |

If the post does not state a location or a specific role, skip it. Do not infer a city from the author's profile or the company's headquarters.

## 4. Deduplicate

Read today's report `reports/daily/YYYY-MM-DD.md`, the previous 7 daily reports under `reports/daily/`, and `reports/job-index.json` before adding a row.

Skip the feed job when:

- the same normalized company + title + location already appears anywhere in today's report (matched, review or an existing feed section);
- the same job is already in `job-index.json` with `appliedOn` set;
- the same job is already in the index as `matched` or `review` (it is already known);
- two feed posts describe the same job; keep the newer or more specific one.

Normalization: lowercase, strip punctuation and gender markers such as `(m/w/d)` and `(all genders)`, and strip legal suffixes such as GmbH, AG, SE, Inc, Ltd and LLC. Never merge different cities.

## 5. Add the section to today's daily report

Edit `reports/daily/YYYY-MM-DD.md`.

- Place a translated `## Feed-sourced jobs` section after the matched-jobs section and before the review and excluded sections.
- If the daily report does not exist yet, create it with the report title and this section, and note that the regular job-discovery run has not written its sections yet.
- If the section already exists, merge new rows; never duplicate a row or overwrite a row the user edited.
- If the report has a run summary table, set its `Feed-sourced jobs` row to the number of rows in this section. Do not invent a run summary table when it is absent.
- Only matching jobs appear. A job matches when the role and location match; other dimensions never exclude it. Non-matching hiring posts and non-hiring posts are not listed anywhere, including the excluded table.
- If no feed job matches, do not add the section.

Fixed table columns:

```markdown
| # | Source | Company | Title | Location | Mode | Posted | Matched keywords | Notes | Link |
|---|---|---|---|---|---|---|---|---|---|
| 1 | LinkedIn Feed | Example GmbH | Senior Frontend Engineer | Berlin | Hybrid | 2h ago | React, TypeScript | 来自 feed; hiring manager post | [Open](URL) |
```

Column rules:

- `Source`: always `LinkedIn Feed`.
- `Company`: the company named in the post. If the author is the company page, use that name. Never guess.
- `Title`: the role as written in the post.
- `Location`: the location stated in the post. Never infer.
- `Mode`: the stated work mode, or `Not specified`.
- `Posted`: the relative post time (`2h ago`, `1 day ago`).
- `Matched keywords`: configured terms actually named in the post; `None matched` when the post names a stack but no configured term matches; `Not stated` when the post names no stack.
- `Notes`: start with `来自 feed` (use `From feed` when the report language is not Chinese), then one short verifiable fact, for example `hiring manager post`, `DM to apply` or `link in comments`. Add `mode not in config`, `stack: <terms>`, `employment: <type>`, `level: <level>`, `language: <language>` or `poster type unclear` when relevant.
- `Link`: the post permalink actually copied from LinkedIn. Never assemble or guess a URL; write `Link unavailable` when no permalink exists.

Renumber the `#` column after merging so it stays sequential within this section.

## 6. Publish the daily report

If `reportRepo` is a non-empty Git URL, publish the updated daily file using the same steps as `job-discovery` section 5:

1. Clone or pull `reportRepo` into a temporary directory.
2. Copy `reports/daily/YYYY-MM-DD.md` to `reports/daily/YYYY-MM-DD.md` there. If the remote file already exists, merge the `Feed-sourced jobs` section into it instead of replacing the file; never drop remote sections.
3. Commit `docs: add feed-sourced jobs for YYYY-MM-DD` and push to the default branch.
4. On authentication or push failure, report it and keep the local report. Never force-push.

Do not publish anything else.

## 7. Report completion

State:

- the number of hiring posts seen;
- the number added to the daily report;
- how many were skipped for a missing title or location;
- how many were skipped as duplicates or already applied;
- the daily report path and whether it was published;
- any access limitation.

Only count posts actually read in the browser. Never claim a post was seen if it was not rendered.
