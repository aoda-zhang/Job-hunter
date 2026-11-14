---
name: linkedin-feed-review
description: Read the LinkedIn Recent feed, reply only to posts whose author role matches jobTitles.include and whose author location is confirmed inside countries/locations, and draft replies. No daily minimum. Read-only.
---

# LinkedIn Feed Review

Read-only. Review the Recent feed, select posts worth replying to, draft replies, write the report. Never post, comment, react, follow, connect or message.

## 1. Read config

Read `job-hunter.config.json`:

- `countries`, `locations` — author location gate. Empty `locations` = whole country.
- `jobTitles.include` — author role gate.
- `technicalKeywords.include`, `.matchMode` — topic gate.
- `linkedinFeedReview` — optional: `lookbackHours`, `maxPosts`, `excludeTopics`, `replyLanguage`.
- `preferredReportLanguage`, `notifications.email`, `reportRepo`.

If `jobTitles.include` and `technicalKeywords.include` are both empty, stop and ask.

## 2. Apply exclusions

Skip a post whose main subject is any `linkedinFeedReview.excludeTopics` entry. Judge the main subject, not keyword mentions. Add no hidden exclusions. If the list is empty, skip none.

## 3. Apply hard gates

Keep a post only when all four pass.

1. **Author role**: require the author's current role to be `jobTitles.include` or a clear variant/synonym. Reject SVP Engineering, CTO, Founder, Engineering Manager, Tech Lead, Head of Engineering, Product Manager, recruiters, coaches, agencies and company pages unless explicitly listed. Skip when the role is unconfirmed.
2. **Author location**: confirm the author is inside `countries`/`locations`. Use the post's stated location first. If absent, open the author's profile once, read-only, and read the location. Skip when missing, private or outside the config. Never infer from company HQ or post language.
3. **Topic**: the post names a configured title, a `technicalKeywords.include` term, or a role-relevant topic (frontend architecture, React/TypeScript, performance, accessibility, component design, engineering hiring, software career).
4. **Reply-worthy**: the post asks a question, shares a lesson/trade-off/decision, makes a discussable claim, or describes a team/way of working.

No daily minimum. Zero selected is valid.

## 4. Read the feed

Follow `.opencode/skills/linkedin-feed-review/references/feed-extraction.md`. Open `https://www.linkedin.com/feed/`, set `Sort by: Recent`, read `div[role="listitem"][componentkey*="update-card"]`, scroll `#workspace`, expand `… more`. Read at most 10 screens; stop after 3 screens with no post in the window.

Treat LinkedIn `1d` as the 24h boundary; include it and mark `24h boundary`. Do not load the following list. Do not click links or interact.

Record author, headline, time, text, permalink, engagement and stated location. Copy a selected post's permalink via its control menu; if unavailable, write `Link unavailable`. Keep all posts, including hiring posts, for `linkedin-feed-jobs`.

## 5. Order and cap

Order: direct questions, then lessons/trade-offs/decisions, then industry/career opinions. Newest first within each group. Select every post that passes, up to `maxPosts`. Do not rank by seniority, followers or score.

## 6. Draft replies

Write one primary and one backup per selected post.

- Primary: one specific follow-up question.
- Backup: add-on, gentle counterpoint, or a user-stated experience.
- Match `replyLanguage` (`auto` = post language).
- 2–4 sentences, 40–90 words.
- Be specific. No "Great post", "Thanks for sharing", links, hashtags or emojis.
- Never ask for a job, referral or CV review. Never pitch.
- Do not disclose relocation, visa, salary, employer or client names.
- Do not repeat top comments.
- Never post or open the comment box.

## 7. Write the report

Write `reports/linkedin-feed/YYYY-MM-DD.md` in `preferredReportLanguage`.

````markdown
# LinkedIn Feed 回复机会 — YYYY-MM-DD

## 今日回复清单

- [ ] **1. Name** — Headline · Topic · Language [· 24h 边界] — [打开原帖](URL)

  > primary

  Backup: backup
````

Then add the run summary:

| 指标 | 值 |
|---|---|
| 时间窗口 | 过去 24 小时 |
| 浏览的帖子 | N |
| 硬过滤（excludeTopics） | N |
| 作者岗位匹配 | N |
| 作者地点确认 | N |
| 话题相关且值得回复 | N |
| 最终入选 | N |
| Feed 招聘帖新增 | N |
| 回复语言 | auto |

Translate the labels into `preferredReportLanguage`.

Add `## Feed 招聘帖` with the matched rows. When none match, write one line `本轮没有匹配的招聘帖。`. Add one `## 覆盖说明` line. Do not add a post-detail section or paste full posts.

### Email and publish

If `notifications.email.enabled`, load `email-notify` and send one email with the checklist replies and job rows.

If `reportRepo` is set, clone/pull it, copy the report to `reports/linkedin-feed/YYYY-MM-DD.md`, commit `docs: add LinkedIn feed review for YYYY-MM-DD`, push and verify. Never force-push. Never publish `job-index.json` or `reports/runs/`.

## 8. Merge

If today's report exists, merge and keep user-edited drafts. Deduplicate by permalink. Do not suggest a post selected in the previous 7 reports. When the user says they replied, mark `[x]` and add `[replied MM-DD]`.

## 9. Finish

Report the path, window, posts reviewed, exclusion count, role-rejected count, location-rejected count, selected count, left-out count, job count, email status, publish status and limitations. State that zero is valid and the feed may not show every post.
