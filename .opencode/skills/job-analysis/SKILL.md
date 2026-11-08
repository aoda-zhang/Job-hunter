---
name: job-analysis
description: Evaluate a German software engineering job description against the candidate profile and produce evidence-based fit analysis.
---

# Job Analysis

Read `config/job-preferences.json` and `config/scoring-rules.json`.

For each posting:
- Separate mandatory requirements from preferred qualifications.
- Compare React/TypeScript depth, frontend ownership, architecture, Node.js, domain experience, seniority, location, work mode, language, and compensation.
- Evaluate English and German requirements precisely.
- Identify stated work-authorization or relocation requirements. If absent, say "Not specified"; do not assume sponsorship is or is not needed.
- Cite exact JD phrases or concise evidence snippets for each major match/gap.
- Return a 0–100 score, strengths, gaps, unknowns, and a concise recommendation.
- Do not inflate scores based on keyword matches alone.
- Never claim the score predicts interview success.
- Never apply or contact the employer.
