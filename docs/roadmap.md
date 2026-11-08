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

## Phase 2 — Discovery quality
- [ ] Improve semantic job-title variants by market and language
- [ ] Add robust JD language detection and short-text handling
- [ ] Add technical-keyword aliases and boundary-aware matching
- [ ] Add review queue for incomplete or ambiguous postings
- [ ] Add company research with citations

## Phase 3 — Daily operations
- [ ] Scheduled execution on the user's machine
- [ ] Failure alerts and run summaries
- [ ] Historical trend and application tracker
- [ ] Optional email delivery of reports

## Non-goals

No candidate-fit scoring, weighted ranking, automatic application rejection, or automated messages. Automatic applications and employer contact are out of scope unless separately designed with explicit user approval at the point of action.
