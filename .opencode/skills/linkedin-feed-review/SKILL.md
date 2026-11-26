---
name: linkedin-feed-review
description: Search LinkedIn posts by topic (frontend and Node.js fullstack in Germany), pick up to 3 posts worth commenting on, and draft possible comment replies. Read-only, no home feed.
---

# LinkedIn comment search

Read-only. Search LinkedIn posts by topic, select the posts worth commenting on,
draft possible comment answers, write the report. Never post, comment, react,
follow, connect or message.

Never read the user's home feed: do not open `https://www.linkedin.com/feed/`, do
not sort by Recent and do not load the following list. Discovery happens only
through the topic searches in section 4.

## 1. Read config

Read `job-hunter.config.json`:

- `platforms.LinkedIn.feedReview` — `searchTopics`, `lookbackHours`, `maxPosts`
  (target and cap, `3` in the shipped config), `maxQueries`,
  `maxPagesPerQuery`, `excludeTopics`, `replyLanguage`.
- `common.countries`, `common.locations` — Germany-relevance gate. Empty
  `common.locations` = whole country.
- `common.technicalKeywords.include`, `.matchMode` — confirms a post is about the
  configured stack.
- `common.preferredReportLanguage`, `common.reportRepo`.

If `platforms.LinkedIn.feedReview.searchTopics` and
`common.technicalKeywords.include` are both empty, stop and ask.

## 2. Apply exclusions

Skip a post whose main subject is any `platforms.LinkedIn.feedReview.excludeTopics`
entry. Judge the main subject, not keyword mentions. Add no hidden exclusions. If
the list is empty, skip none.

## 3. Apply hard gates

Keep a post only when all three pass.

1. **Topic**: the post is mainly about frontend or Node.js fullstack work —
   frontend architecture, React, TypeScript, JavaScript, HTML/CSS, component
   design, performance, accessibility, Node.js, Express, NestJS, API design or
   fullstack JavaScript delivery. A `common.technicalKeywords.include` term
   confirms the topic; a role-relevant discussion that names none of them still
   passes when the subject is clearly frontend or Node.js fullstack.
2. **Germany**: confirm the post or its author is tied to
   `common.countries`/`common.locations`. Use the post's stated location or an
   explicit German market/team/community reference first. If absent, open the
   author's profile once, read-only, and read the location. Skip when missing,
   private or outside the config. Never infer from company HQ, post language or
   the platform domain.
3. **Reply-worthy**: the post asks a question, shares a lesson/trade-off/decision,
   makes a discussable claim, or describes a team/way of working.

No `common.jobTitles.include` role match is required. Prefer practitioner voices
(engineers, developers, tech leads, founders building the product) and skip
recruiter/agency hiring posts through `excludeTopics`.

Target `maxPosts` selected posts (3). Return fewer only when fewer pass every
gate; zero is valid.

## 4. Search posts

Follow `.opencode/skills/linkedin-feed-review/references/post-search.md`. Run one
content search per configured topic, sorted by date posted, inside the
`lookbackHours` window. Search only the configured topics; never read the home
feed.

Record author, headline, time, text, permalink, engagement and stated location.
Copy a selected post's permalink via its control menu; if unavailable, write
`Link unavailable`. Keep all posts, including hiring posts, for
`linkedin-feed-jobs`.

## 5. Order and cap

Order: direct questions, then lessons/trade-offs/decisions, then industry/career
opinions. Newest first within each group. Select every post that passes, up to
`maxPosts`. Do not rank by seniority, followers or score.

## 6. Draft possible comments

Write two ready-to-send options per selected post.

- **Primary**: one specific follow-up question.
- **Backup**: add-on, gentle counterpoint, or a user-stated experience.
- Match `replyLanguage` (`auto` = post language).
- 2–4 sentences, 40–90 words.
- Be specific. No "Great post", "Thanks for sharing", links, hashtags or emojis.
- Never ask for a job, referral or CV review. Never pitch.
- Do not disclose relocation, visa, salary, employer or client names.
- Do not repeat existing comments.
- Never post or open the comment box.

## 7. Write the report

Write `reports/linkedin-feed/YYYY-MM-DD.md` in `common.preferredReportLanguage`.

````markdown
# LinkedIn comment opportunities — YYYY-MM-DD

## Today's comment list

- [ ] **1. Name** — Headline · Topic · Language [· 24h boundary] — [Open post](URL)

  > Primary: primary

  Backup: backup
````

Then add the run summary:

| Metric | Value |
|---|---|
| Time window | past 24 hours |
| Search topics | N |
| Queries run | N |
| Posts viewed | N |
| Excluded by topics | N |
| Topic matched | N |
| Germany confirmed | N |
| Relevant and worth commenting | N |
| Selected | N (target 3) |
| New feed hiring posts | N |
| Reply language | auto |

Translate the labels into `common.preferredReportLanguage`.

Add `## Search topics` with the queries actually run and their per-query counts.
Add `## Feed hiring posts` with the matched rows. When none match, write one line
`No matching hiring posts this run.`. Add one `## Coverage notes` line. Do not add
a post-detail section or paste full posts.

### Publish

If `common.reportRepo` is set, run `.opencode/scripts/report-publish.sh reports/linkedin-feed/YYYY-MM-DD.md reports/linkedin-feed/YYYY-MM-DD.md`; it pushes and arms the one-shot expiry timer and commits with the fixed message `test something`. Never force-push. Never publish `reports/runs/` or `reports/applications/`. Published copies expire per `common.reportExpiryHours`; with `reportExpiryMode: "delete-repo"` the repo itself is deleted, so recreate it with `gh repo create <owner>/<name> --public` when the clone reports it missing.

## 8. Merge

If today's report exists, merge and keep user-edited drafts. Deduplicate by
permalink. Do not suggest a post selected in the previous 7 reports. When the user
says they commented, mark `[x]` and add `[commented MM-DD]`.

## 9. Finish

Report the path, window, search topics, queries run, posts reviewed, exclusion
count, topic-rejected count, location-rejected count, selected count, left-out
count, job count, publish status and limitations. State that fewer
than three is valid and that search results may not show every post.
