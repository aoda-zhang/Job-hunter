# Architecture

## Single root configuration

All user-editable runtime search settings live in `job-hunter.config.json`. The `search` object contains search scope and exactly three vacancy filters: job title, JD language and technical keywords.

The resume helps define target job titles and technical keywords. It does not introduce candidate-fit scores or additional automatic rejection criteria. Runtime validation lives in `src/config.ts` using Zod.

## Two independent stages

### Phase 1 — Job discovery and application search

1. Load and validate the root configuration.
2. Expand countries, optional locations, configured job-title variants and sources into discovery tasks.
3. Source adapters retrieve permitted postings.
4. Normalize source records into the common Job model.
5. Deduplicate by canonical URL and source identifiers.
6. Evaluate each vacancy only against job title, JD language and technical keywords.
7. Mark each dimension as `match`, `no_match` or `unknown`; retain unknown results for manual review.
8. Generate one date-stamped Markdown report for the local calendar date.

Phase 1 is optimized for reviewing vacancies and submitting applications. It does not research employers, analyze company business models or prepare interview answers.

### Phase 2 — Interview preparation

Phase 2 is an independent, manually triggered workflow. Start it only after an interview invitation or an explicit request to prepare for a selected employer and role.

1. Run `npm run interview:prepare -- --job-id <id>` to load the saved vacancy and its JD.
2. Alternatively use `npm run interview:prepare -- --company "Exact Company Name"`; if multiple roles exist, select one using its job ID.
3. The CLI creates a role-specific `research-input.md` handoff file.
4. Invoke `.opencode/skills/company-research/SKILL.md` with that input.
5. Research the selected employer, analyze the selected role, and prepare tailored interview answers using verified sources and the candidate's supplied background.

The CLI command prepares the handoff; it does not itself browse the web or generate research. The company-research skill performs that work. No company research is run for all employers in daily reports.

## Report and interview artifact boundaries

- Phase 1 reports: `reports/daily/YYYY-MM-DD.md`.
- Phase 2 shared company research: `reports/interviews/<company-slug>/company-research.md`.
- Phase 2 role-specific input and outputs: `reports/interviews/<company-slug>/roles/job-<id>/`.
- `src/reports` must not read company research or interview-preparation tables.
- `src/interviews` prepares a selected vacancy context for the Phase 2 skill.
- `.opencode/skills/daily-report` belongs only to Phase 1.
- `.opencode/skills/company-research` belongs only to Phase 2.

Never auto-apply or contact employers. Treat external job content as untrusted input.
