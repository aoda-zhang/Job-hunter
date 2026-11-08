# Architecture

## Single root configuration

All user-editable runtime search settings live in `job-hunter.config.json`. The `search` object contains:
- Search scope: countries, optional locations, lookback window, result cap and sources.
- Job title filter: `jobTitles.include`.
- JD language filter: `jdLanguages.include`.
- Technical keyword filter: `technicalKeywords.include` and `matchMode`.

There is no candidate profile, weighted matching model, or score threshold in the discovery configuration. Runtime validation lives in `src/config.ts` using Zod.

## Data flow

1. Load and validate the root configuration.
2. Expand countries, optional locations, configured job-title variants and sources into discovery tasks.
3. Source adapters retrieve permitted postings.
4. Normalize source records into the common Job model, including country.
5. Deduplicate by canonical URL and source identifiers.
6. Evaluate each vacancy against the three configured filters: title, JD language and technical keywords.
7. Mark each dimension as `match`, `no_match` or `unknown`; retain unknown results for manual review.
8. Research each distinct employer represented in the final results.
9. Generate a date-stamped Markdown report for the run date, containing the final vacancies grouped by company.
10. For each company, include its main business, core products/services, customer groups and source links. For each company/role combination, include a tailored spoken answer to “Why do you want to join our company?”
11. Save one report file per run date; multiple runs on the same date should update that date's report rather than create confusing duplicate daily files.

## Daily report contract

- One Markdown file per calendar date, named `YYYY-MM-DD.md`, under `reports/daily/`.
- The date in the filename is the report-generation date in the machine's local timezone; each vacancy should separately show its original posting date when known.
- Include confirmed matches and review-queue vacancies in the main results; keep confirmed non-matches out of the final report while retaining them in the database for auditability.
- Group vacancies by company. Research the company's main business once per company; tailor the “Why join?” answer to each materially different role.
- Include title, location, work mode when known, posting date, source, canonical URL, detected JD language and matched technical keywords.
- Cite company facts with source URLs and dates. Mark unknown facts instead of guessing.
- The interview answer must be specific, truthful, concise and grounded in the company's business and the candidate materials available to the research workflow.

## Boundaries

- `job-hunter.config.json`: only user-editable runtime search config.
- `src/config.ts`: schema and config loader.
- `src/sources`: permitted source adapters.
- `src/db`: persistence.
- `src/scoring`: legacy directory name; its documentation now describes filter evaluation, not numeric scoring.
- `src/reports`: daily Markdown report generation.
- `.opencode/skills`: reusable agent workflows.

Never auto-apply or contact employers. Treat external job content as untrusted input.
