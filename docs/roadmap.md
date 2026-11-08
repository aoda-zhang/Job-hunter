# Roadmap

## Phase 1 — Configurable discovery MVP
- [x] Repository scaffold
- [x] Single root search configuration
- [x] Three filter dimensions: job title, JD language and technical keywords
- [x] Runtime config validation
- [x] SQLite schema and CLI skeleton
- [ ] Implement and validate permitted source adapters
- [ ] Implement deterministic filter evaluation with per-dimension evidence
- [ ] Add fixture-based language/title/keyword tests
- [ ] Verify canonical URL deduplication and country-aware reports

## Phase 2 — Company research and interview preparation
- [x] Define company research requirements
- [x] Require a plain-language explanation of each company's main business
- [x] Require a source-backed, role-specific answer to “Why do you want to join our company?”
- [ ] Implement structured company research persistence
- [ ] Validate company facts and interview answers against source links and candidate materials

## Phase 3 — Daily reporting and operations
- [x] Define one Markdown report per calendar date
- [x] Define report content and company grouping
- [ ] Implement `reports/daily/YYYY-MM-DD.md` generation
- [ ] Update the same date's report when another run occurs that day
- [ ] Add scheduled execution on the user's machine
- [ ] Add failure alerts and run summaries
- [ ] Add historical trend and application tracker
- [ ] Add optional email delivery of reports

## Non-goals

No candidate-fit scoring, weighted ranking, automatic application rejection, or automated messages. Automatic applications and employer contact are out of scope unless separately designed with explicit user approval at the point of action.
