# Step 2 — Merge and shallow-filter

Read this file after every source in step 1 is collected. It turns the raw `job-audit` cards into one row per vacancy and decides which rows go to JD review.

## 1. Merge

1. Deduplicate by canonical URL / job ID first.
2. Then deduplicate by normalized `company + title + city` across this pass's titles.
3. One vacancy = one row. Keep every search title that returned it in `Search titles`.
4. Cross-source duplicates are annotated per the cross-source rules in `SKILL.md` §2 — never merged, never decided differently.
5. A same-platform duplicate with a different job ID (multi-city, repost, bilingual) is flagged `⚠️ possible duplicate`; add `possibly applied MM-DD` when the earlier twin was applied to. Use the known set from `SKILL.md` §2 plus this run's rows.

## 2. Skip sets

Apply, before the title filter:

- the previous-run set → status `previously reported`;
- `appliedOn` entries → status `already applied (skipped)`;
- the applied set from another platform → status `applied on another platform (skipped)`.

None of these are opened in step 3 and none appear in the matched, review or excluded tables.

## 3. Shallow title filter

This is a **title-only** filter. Drop a row only when the title is *obviously* outside the family:

- it names a clearly different profession: `UX Designer`, `Product Manager`, `Talent Acquisition`, `Sales Engineer`, `Accountant`;
- it contains a `common.jobTitles.excludeWords` word: `Lead`, `Staff`, `Principal`, `Architect`, `Manager`, `Head of`, `CTO`, `Director`, `VP`;
- it names a clearly different software discipline: `Embedded`, `SAP Functional Consultant`, `DevOps`, `Data Scientist`.

**Never drop** `Software Engineer`, `Developer`, `Engineer`, `Product Engineer`, `Application Engineer`, `Full-Stack`, `Frontend`, `Backend`, `Web`, a German equivalent (`Entwickler`, `Ingenieur`, `Softwareentwickler`, …), or any title containing a configured role noun.

When in doubt, keep it. `Software Engineer` is not a mismatch — it is an unknown that step 3 decides from the JD. Never remove a row because it "looks unlikely".

## 4. Update job-audit

- Set `Status` to `removed by shallow filter` for every dropped row; the title itself is the reason.
- Leave every surviving row at `sent to JD review`.
- Update the counts line:

```markdown
This run: 2 search titles · 324 cards · 228 unique · 18 removed by shallow filter · 210 sent to JD review
```

- The merged list keeps its merged order (company, then title); `#` restarts at 1.

## 5. Hand off

Step 3 opens the `sent to JD review` rows in the order they appear in `job-audit`, one at a time. A row that was deduplicated, skipped or shallow-filtered is never opened.
