---
name: job-analysis
description: Evaluate job descriptions in any configured market against the candidate and matching settings in the single root config.
---

# Job Analysis

Read `job-hunter.config.json`. Use:
- `candidate` for skills, experience, languages, compensation reference and work-authorization context.
- `matching` for scoring weights, thresholds and analysis rules.
- `search` only for the user's configured target markets and role scope.

For each vacancy:
- Identify its country and distinguish it from the candidate's current country.
- Separate mandatory requirements from preferred qualifications.
- Compare role scope, skills, architecture, domain experience, seniority, location, work mode, language, compensation and work authorization.
- Interpret country-specific requirements in the context of the vacancy's country; verify legal claims from authoritative sources.
- If sponsorship, language, salary or remote eligibility is unstated, mark it unknown.
- Return a 0–100 score with evidence, strengths, gaps, unknowns and recommendation.
- A score is decision support, not interview probability.
- Never apply or contact the employer.
