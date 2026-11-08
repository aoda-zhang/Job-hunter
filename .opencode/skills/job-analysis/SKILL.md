---
name: job-analysis
description: Evaluate job descriptions across markets against the candidate profile with country-aware, evidence-based analysis.
---

# Job Analysis

Read `config/config.json`, `config/job-preferences.json`, and `config/scoring-rules.json`.

For each posting:
- Identify the vacancy's country and distinguish it from the candidate's current location.
- Separate mandatory requirements from preferred qualifications.
- Compare role scope, core skills, architecture, domain experience, seniority, location, work mode, language, compensation, and work authorization.
- Interpret language, salary, benefits, and work-authorization requirements in the context of the vacancy's country.
- Identify stated relocation or work-authorization requirements. If absent, say "Not specified"; do not assume sponsorship is or is not needed.
- Cite exact JD phrases or concise evidence snippets for each major match/gap.
- Return a 0–100 score, strengths, gaps, unknowns, and a concise recommendation.
- Do not inflate scores based on keyword matches alone.
- Never claim the score predicts interview success.
- Never apply or contact the employer.
