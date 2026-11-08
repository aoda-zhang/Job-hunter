# Roadmap

## Phase 1 — Job discovery and application search
- [x] Repository scaffold
- [x] Single root search configuration
- [x] Three filter dimensions: job title, JD language and technical keywords
- [x] Runtime config validation
- [x] SQLite schema and CLI skeleton
- [x] Define one Markdown report per calendar date
- [x] Implement daily report generation, focused only on vacancy discovery
- [x] Keep company research and interview answers out of daily reports
- [ ] Implement and validate permitted source adapters
- [x] Implement deterministic filter evaluation with per-dimension evidence
- [x] Add fixture-based language/title/keyword tests
- [ ] Verify canonical URL deduplication and country-aware reports
- [ ] Add scheduled execution on the user's machine

## Phase 2 — Interview preparation (independent skill)
- [x] Define company research as an independent, manually triggered skill
- [x] Define a CLI handoff that loads a selected vacancy and its stored JD by job ID or exact company name
- [x] Generate a role-specific research-input.md file without running research during discovery
- [x] Define separate shared company research and per-role interview output locations
- [x] Require source-backed research into the selected company's main business
- [x] Define role-specific analysis and tailored interview-answer requirements
- [ ] Implement automated, source-backed research for a user-selected company through the agent runtime
- [ ] Implement generation and validation of interview answers using verified company facts and candidate materials
- [ ] Persist completed company research and role-specific interview materials
- [ ] Add interview-stage report generation under `reports/interviews/<company-slug>/`

## Future improvements
- [ ] Add failure alerts and run summaries
- [ ] Add historical trend and application tracker
- [ ] Add optional email delivery of daily discovery reports

## Non-goals

No candidate-fit scoring, weighted ranking, automatic application rejection, or automated messages. Automatic applications and employer contact are out of scope unless separately designed with explicit user approval at the point of action.
