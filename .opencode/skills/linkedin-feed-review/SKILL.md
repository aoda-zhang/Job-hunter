---
name: linkedin-feed-review
description: Read the LinkedIn Recent feed, reply only to posts whose author role matches jobTitles.include and whose author location is confirmed inside countries/locations, and draft replies. No daily minimum. Read-only.
---

# LinkedIn Feed Review

Read-only. Review the Recent feed, select posts worth replying to, draft replies, write the report. Never post, comment, react, follow, connect or message.

## 1. Read config

Read `job-hunter.config.json`:

- `common.countries`, `common.locations` — author location gate. Empty `common.locations` = whole country.
- `common.jobTitles.include` — author role gate.
- `common.technicalKeywords.include`, `.matchMode` — topic gate.
- `platforms.LinkedIn.feedReview` — optional: `lookbackHours`, `maxPosts`, `excludeTopics`, `replyLanguage`.
- `common.preferredReportLanguage`, `notifications.email`, `common.reportRepo`.

If `common.jobTitles.include` and `common.technicalKeywords.include` are both empty, stop and ask.

## 2. Apply exclusions

Skip a post whose main subject is any `platforms.LinkedIn.feedReview.excludeTopics` entry. Judge the main subject, not keyword mentions. Add no hidden exclusions. If the list is empty, skip none.

## 3. Apply hard gates

Keep a post only when all four pass.

1. **Author role**: require the author's current role to be `common.jobTitles.include` or a clear variant/synonym. Reject SVP Engineering, CTO, Founder, Engineering Manager, Tech Lead, Head of Engineering, Product Manager, recruiters, coaches, agencies and company pages unless explicitly listed. Skip when the role is unconfirmed.
2. **Author location**: confirm the author is inside `common.countries`/`common.locations`. Use the post's stated location first. If absent, open the author's profile once, read-only, and read the location. Skip when missing, private or outside the config. Never infer from company HQ or post language.
3. **Topic**: the post names a configured title, a `common.technicalKeywords.include` term, or a role-relevant topic (frontend architecture, React/TypeScript, performance, accessibility, component design, engineering hiring, software career).
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

Write `reports/linkedin-feed/YYYY-MM-DD.md` in `common.preferredReportLanguage`.

````markdown
# LinkedIn Feed reply opportunities — YYYY-MM-DD

## Today's reply list

- [ ] **1. Name** — Headline · Topic · Language [· 24h boundary] — [Open post](URL)

  > primary

  Backup: backup
````

Then add the run summary:

| Metric | Value |
|---|---|
| Time window | past 24 hours |
| Posts viewed | N |
| Excluded by topics | N |
| Author role matched | N |
| Author location confirmed | N |
| Relevant and worth replying | N |
| Selected | N |
| New feed hiring posts | N |
| Reply language | auto |

Translate the labels into `common.preferredReportLanguage`.

Add `## Feed hiring posts` with the matched rows. When none match, write one line `No matching hiring posts this run.`. Add one `## Coverage notes` line. Do not add a post-detail section or paste full posts.

### Email and publish

If `notifications.email.enabled`, load `email-notify` and send one email with the checklist replies and job rows.

If `common.reportRepo` is set, run `.opencode/scripts/report-publish.sh reports/linkedin-feed/YYYY-MM-DD.md reports/linkedin-feed/YYYY-MM-DD.md "docs: add LinkedIn feed review for YYYY-MM-DD"`; it pushes and arms the one-shot expiry timer. Never force-push. Never publish `reports/runs/` or `reports/applications/`. Published copies expire per `common.reportExpiryHours`; with `reportExpiryMode: "delete-repo"` the repo itself is deleted, so recreate it with `gh repo create <owner>/<name> --public` when the clone reports it missing.

## 8. Merge

If today's report exists, merge and keep user-edited drafts. Deduplicate by permalink. Do not suggest a post selected in the previous 7 reports. When the user says they replied, mark `[x]` and add `[replied MM-DD]`.

## 9. Finish

Report the path, window, posts reviewed, exclusion count, role-rejected count, location-rejected count, selected count, left-out count, job count, email status, publish status and limitations. State that zero is valid and the feed may not show every post.
