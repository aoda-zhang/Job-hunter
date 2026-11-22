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

- the previous-run set → status `previously reported` (built from the previous run's `job-audit.md` merged list, every status; see `job-index-and-audit.md` §1);
- entries in today's `reports/applications/YYYY-MM-DD.md` → status `already applied (skipped)`;
- the applied set from another platform → status `applied on another platform (skipped)`.

None of these are opened in step 3 and none appear in the matched, review or excluded tables.

## 3. Primary-stack filter

Before the title filter, apply the primary-stack gate. It is title-only and intentionally runs before the `jobTitles.include` guard.

1. Normalize and translate the published title as in §4.1.
2. Match each `common.jobTitles.stackExclude` entry case-insensitively as a **whole word or whole phrase**. Do not use naive substring matching: `java` must not match `JavaScript`.
3. If the title contains a `stackExclude` term and does **not** contain any `common.jobTitles.stackIncludeOverride` term, set the row to `removed by primary-stack filter` and never open the JD.
4. If the title also contains a `stackIncludeOverride` term (for example `Full-Stack Developer (React/Python)`), keep it for JD review.

Examples:

- `Senior Software Engineer (Java/SpringBoot)` → removed (Java/Spring, no React/TS/JS/frontend override).
- `Senior Python Software Engineer` → removed (Python, no override).
- `Full-Stack Developer (Python)` → removed (Python, no explicit frontend override).
- `Full-Stack Developer (React/Python)` → kept (React override); step 3 still applies the primary-stack gate.
- `JavaScript Developer` → kept (`JavaScript` is not `Java`; whole-word matching).

Why this exists: a generic `Software Engineer` title can hide a Java/Python role. A Java/Python primary stack is a confirmed mismatch even when React appears as a secondary keyword.

## 4. Shallow title filter

This is a **title-only** filter. First check `common.jobTitles.shallowExclude`: when the published title contains any configured string (case-insensitive substring), set the row to `removed by shallow filter` immediately — no JD is opened. **Guard:** after the usual normalization and German-title translation, a title that contains any `common.jobTitles.include` phrase is never dropped by this list; it goes to JD review. The list only removes titles that cannot be a configured role anyway (e.g. pure SAP/consultant/internship titles). Then drop a row when the title is *obviously* outside the family:

- it names a clearly different profession: `UX Designer`, `Product Manager`, `Talent Acquisition`, `Sales Engineer`, `Accountant`;
- it contains a `common.jobTitles.excludeWords` word: `Lead`, `Staff`, `Principal`, `Architect`, `Manager`, `Head of`, `CTO`, `Director`, `VP`;
- it names a clearly different software discipline: `Embedded`, `SAP Functional Consultant`, `DevOps`, `Data Scientist`.

**Never drop** `Software Engineer`, `Developer`, `Engineer`, `Product Engineer`, `Application Engineer`, `Full-Stack`, `Frontend`, `Backend`, `Web`, a German equivalent (`Entwickler`, `Ingenieur`, `Softwareentwickler`, …), or any title containing a configured role noun.

When in doubt, keep it. `Software Engineer` is not a mismatch — it is an unknown that step 3 decides from the JD. Never remove a row because it "looks unlikely".

### 4.1 Early strict title match (`common.jobTitles.earlyStrictMatch`)

When the flag is `true`, apply the step-3 title gate here instead of opening the JD:

- Normalize and translate the published title exactly as `step-3-jd-review.md` §2.1 describes (gender markers and punctuation stripped, `Softwareentwickler` → `Software Engineer`, `Entwickler` → `Developer`, `Ingenieur` → `Engineer`, …).
- If the normalized title does not contain any `common.jobTitles.include` phrase, or contains a `jobTitles.excludeWords` word, set the row to `removed by early strict title match` and never open it.
- This is a title-only gate: it does not read the JD, does not judge language, keywords, work mode or seniority.
- With the flag `false` the old behaviour applies: ambiguous titles are kept for step 3.

## 5. Update job-audit

- Set `Status` to `removed by shallow filter` for every dropped row; the title itself is the reason.
- Leave every surviving row at `sent to JD review`.
- Update the counts line:

```markdown
This run: 2 search titles · 324 cards · 228 unique · 18 removed by shallow filter · 210 sent to JD review
```

- The merged list keeps its merged order (company, then title); `#` restarts at 1.

## 6. Hand off

Step 3 opens the `sent to JD review` rows in the order they appear in `job-audit`, one at a time. A row that was deduplicated, skipped or shallow-filtered is never opened.
