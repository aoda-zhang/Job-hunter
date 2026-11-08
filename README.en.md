# Job Hunter Configuration Guide

Job Hunter is a multi-country, multi-role job discovery tool with two independent stages:

- **Phase 1 — Job discovery and applications:** search for vacancies based on your target roles, then filter only by job title, JD language and technical keywords. Generate a daily Markdown report.
- **Phase 2 — Interview preparation:** after receiving an interview invitation, manually invoke an independent company-research skill for the selected employer and role.

## 1. Single root configuration

All search settings live in `job-hunter.config.json`.

Country, location, posting recency and source define the search scope; they are not candidate-fit scoring criteria. Your resume and technical background help define target job titles and keywords, but do not introduce extra candidate scoring or automatic rejection rules.

## 2. Complete configuration example

```json
{
  "search": {
    "countries": ["Germany"],
    "locations": ["Munich", "Berlin", "Hamburg", "Remote"],
    "lookbackHours": 72,
    "maxResultsPerSource": 50,
    "sources": ["company-career-pages", "LinkedIn", "StepStone"],
    "jobTitles": {
      "include": ["Senior Frontend Engineer", "Senior Frontend Developer", "Frontend Platform Engineer", "Senior React Engineer", "Senior Full-Stack Engineer"]
    },
    "jdLanguages": {
      "include": ["English", "German"]
    },
    "technicalKeywords": {
      "include": ["React", "TypeScript", "JavaScript", "HTML", "CSS", "Next.js", "Node.js", "NestJS", "Express", "Redux"],
      "matchMode": "any"
    }
  }
}
```

## 3. Phase 1 — Job discovery and application search

Run `npm run report` (or `npm run dev -- report`) to create or replace the daily report:

`reports/daily/YYYY-MM-DD.md`

Vacancies are grouped by company for readability only. Each vacancy includes:
- Job title and company.
- Country, location and work mode when known.
- Detected JD language.
- Configured technical keywords found in the JD.
- Filter status and evidence for the three dimensions.
- Posting date and discovery date.
- Source and job URL.
- A concise JD summary and collapsible original description when available.

The report includes confirmed matches and items requiring manual review. Confirmed non-matches are excluded from the report body but retained in the database audit trail. Unknown or incomplete fields are explicitly marked rather than silently discarded.

**Phase 1 does not perform company deep research or generate interview answers.** Its purpose is to help you find, review and apply for relevant vacancies.

## 4. Phase 2 — Independent company research and interview preparation

After receiving an interview invitation, manually invoke:

`.opencode/skills/company-research/SKILL.md`

This independent skill covers:
1. **Company research:** main business, products/services, customer groups, business model, headquarters and major markets.
2. **Market context:** industry position, competitors and recent material business developments, where reliable sources are available.
3. **Role analysis:** responsibilities, technical stack, business context and links to your actual project experience.
4. **Interview preparation:** “Why do you want to join our company?”, “Why this position?”, “What can you bring?”, plus likely technical and behavioral questions.

Save outputs separately under:

`reports/interviews/<company-slug>/`

Recommended files are `company-research.md`, `role-analysis.md` and `interview-preparation.md`. Company facts may be reused for another role at the same employer, but role analysis and answers must be tailored to each vacancy.

This skill is not triggered during routine discovery and does not research every company in the daily report.

## 5. The three vacancy filters

| Dimension | Config field | Behavior |
|---|---|---|
| Job title | `jobTitles.include` | Match common title variants and semantic equivalents |
| JD language | `jdLanguages.include` | Detect the actual primary JD language; do not infer it from country |
| Technical keywords | `technicalKeywords.include` | Look for configured technologies in the JD |

For `technicalKeywords.matchMode`:
- `any`: one keyword hit is sufficient; recommended to reduce false negatives.
- `all`: every configured keyword must be present.

Mark a vacancy Matched only when all three dimensions are confirmed matches. Mark Not matched only when there is clear mismatch evidence. Keep ambiguous or incomplete cases as Review.

## 6. Explicit non-filters

Do not filter by years of experience, seniority, salary, visa/work authorization, candidate language proficiency, industry background or architecture experience. There is no overall candidate-fit score or score-based rejection threshold.

## 7. Validation and current limitations

Run `npm run config:check` to validate the configuration. The Zod schema is in `src/config.ts`.

The daily Markdown report generator is implemented. Job-board adapters, end-to-end vacancy collection and deterministic three-dimension filtering remain pending. The independent Phase 2 skill specification and persistence tables are defined, while automated company research, interview-answer generation and interview-material persistence are still pending.

The project does not automatically submit applications or contact employers. Respect each source's terms, access controls and rate limits.
