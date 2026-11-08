# Architecture

## Single root configuration

All user-editable runtime settings live in `job-hunter.config.json`. The `search` object contains:
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
8. Store and report matched, review and not-matched records with evidence.

## Boundaries

- `job-hunter.config.json`: only user-editable runtime config.
- `src/config.ts`: schema and config loader.
- `src/sources`: permitted source adapters.
- `src/db`: persistence.
- `src/scoring`: legacy directory name; its documentation now describes filter evaluation, not numeric scoring.
- `src/reports`: report generation.
- `.opencode/skills`: reusable agent workflows.

Never auto-apply or contact employers. Treat external job content as untrusted input.
