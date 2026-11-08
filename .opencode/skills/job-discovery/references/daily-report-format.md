# Daily Job Report Reference

This document is the canonical format specification for every Job Hunter daily report.

The `job-discovery` skill MUST read and follow this document before creating or updating any file under `reports/daily/`. If report-format instructions elsewhere conflict with this document, this document defines the report structure; the skill still defines the search and matching logic.

## File location

Use one Markdown file per local calendar date:

`reports/daily/YYYY-MM-DD.md`

Create `reports/daily/` when it does not exist. When today's report already exists, preserve its existing entries and append or update findings. Never overwrite useful findings from an earlier run on the same date.

## Report structure

Use these sections in this order:

1. Report title and run metadata.
2. Search scope.
3. Run summary.
4. Matched vacancies.
5. Vacancies requiring review.
6. Excluded vacancies summary.
7. Search limitations and notes.

### 1. Title and run metadata

Start with:

```markdown
# LinkedIn Job Discovery — YYYY-MM-DD

- **Run time:** YYYY-MM-DD HH:mm (local time; timezone if known)
- **Source:** LinkedIn
- **Configuration:** `job-hunter.config.json`
```

Do not invent a timezone. If the local timezone is unknown, label the time as local time without an offset.

### 2. Search scope

Record the actual scope used in the run:

- Countries
- Locations
- Job-title search terms
- Posting lookback window
- Maximum inspection limit

These are discovery parameters, not additional vacancy-matching dimensions.

### 3. Run summary

Use a compact table:

| Metric | Count |
|---|---:|
| Search results encountered | N |
| Distinct vacancy pages opened | N |
| Job descriptions inspected | N |
| Matched | N |
| Needs review | N |
| Confirmed non-matches excluded | N |

Only report counts supported by the actual browser session. If a count cannot be established, write `Not available`; do not estimate it. Search-result cards are not equivalent to opened vacancy pages or inspected JDs.

### 4. Matched vacancies

Create one subsection per company. Each vacancy must use this structure:

```markdown
### Company Name

#### Job Title

- **Status:** matched
- **Location:** As displayed / Not specified
- **Work mode:** On-site / Hybrid / Remote / Not specified
- **Posted:** Date as displayed / Not specified
- **Discovered:** YYYY-MM-DD
- **JD language:** English (evidence: ...)
- **Job title check:** Match — brief title-family evidence.
- **JD language check:** Match — brief language evidence.
- **Technical keyword check:** Match — list configured keywords found.
- **Source:** LinkedIn
- **Job URL:** https://...

**Role summary**
- Concise summary of responsibilities.
- Main required technologies, based on the JD.

**JD content**
Include the full JD when reasonably short. For long JDs, include a useful, faithful excerpt and explicitly state that it is an excerpt; retain the direct source URL.
```

Do not infer missing location, work mode or posting date. Do not add a fit score, ranking, recommendation tier or candidate-profile assessment.

### 5. Vacancies requiring review

Use the same vacancy structure, but set `Status: review`. For each uncertain dimension:

- State `Unknown` or `Needs manual review`.
- Explain exactly what evidence is missing or ambiguous.
- Do not describe an unknown result as a match or mismatch.
- Keep the vacancy visible even when the JD is inaccessible, too short, mixed-language or truncated, provided there is enough verified information to identify the vacancy.

### 6. Excluded vacancies summary

Do not put confirmed `not_matched` vacancies in the main vacancy sections. Provide a compact summary with:

- Total number excluded.
- Mismatch dimension(s): job title, JD language and/or technical keywords.
- A short reason where evidence is available.

Do not expose long JD text for excluded jobs unless the user explicitly asks for it.

### 7. Limitations and notes

Record relevant operational limitations, for example:

- LinkedIn login/session unavailable.
- Search result pages inaccessible.
- JD content hidden or truncated.
- Browser tool unavailable.
- Search stopped at the configured inspection limit.

Distinguish clearly between vacancies seen in search results and vacancies whose actual JD was opened and inspected.

## Evidence and consistency rules

- Use only facts visible on the LinkedIn page or verified in the browser session.
- Keep the three matching dimensions separate and show brief evidence for each.
- The overall status is `matched` only when all three dimensions are confirmed matches.
- The overall status is `review` when no dimension is a confirmed mismatch and at least one is unknown.
- A confirmed mismatch in any one dimension means `not_matched`.
- Preserve the original job URL. Do not invent or reconstruct an unverified URL.
- Use `Not specified` for absent optional metadata.
- Use the same labels and section order across dates so reports remain easy to scan and compare.
- Group by company for readability only. Do not rank vacancies.
- Avoid duplicating the same vacancy in one report. Prefer the canonical LinkedIn job URL as the deduplication key.
- When updating an existing daily report, preserve prior entries and refresh only when new evidence is available. Do not silently downgrade or remove a previously verified entry.

## Compact example

```markdown
# LinkedIn Job Discovery — 2026-11-08

- **Run time:** 2026-11-08 09:30 (local time)
- **Source:** LinkedIn
- **Configuration:** `job-hunter.config.json`

## Search scope
- **Countries:** Germany
- **Locations:** Munich, Berlin
- **Title terms:** Senior Frontend Engineer; Senior React Engineer
- **Lookback:** 72 hours
- **Inspection limit:** 50

## Run summary
| Metric | Count |
|---|---:|
| Search results encountered | 18 |
| Distinct vacancy pages opened | 12 |
| Job descriptions inspected | 10 |
| Matched | 6 |
| Needs review | 2 |
| Confirmed non-matches excluded | 2 |

## Matched vacancies

### Example Company

#### Senior Frontend Engineer
- **Status:** matched
- **Location:** Munich, Germany
- **Work mode:** Hybrid
- **Posted:** 2 days ago
- **Discovered:** 2026-11-08
- **JD language:** English (evidence: description body)
- **Job title check:** Match — frontend engineering role.
- **JD language check:** Match — JD is written in English.
- **Technical keyword check:** Match — React, TypeScript.
- **Source:** LinkedIn
- **Job URL:** https://www.linkedin.com/jobs/view/...

**Role summary**
- Build and maintain frontend product features.
- Main technologies: React and TypeScript.

**JD content**
Excerpt: [faithful excerpt from the inspected JD]. Full description is available at the source URL.
```

The example is illustrative only. Never copy its company, vacancy, URL, dates, evidence or counts into a real report.
