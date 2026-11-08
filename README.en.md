# Job Hunter Configuration Guide

Job Hunter has two independent stages:

- **Phase 1 — Job discovery and applications:** search and filter vacancies using only job title, JD language and technical keywords. Produce a daily Markdown report.
- **Phase 2 — Interview preparation:** after an interview invitation, manually research the selected company and role using a separate skill.

## 1. Single root configuration

All search settings live in `job-hunter.config.json`. Country, location, posting recency and source define search scope, not candidate-fit scoring. Your resume helps define target titles and technical keywords; it does not add extra automatic rejection criteria.

## 2. Configuration example

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
    "jdLanguages": { "include": ["English", "German"] },
    "technicalKeywords": {
      "include": ["React", "TypeScript", "JavaScript", "HTML", "CSS", "Next.js", "Node.js", "NestJS", "Express", "Redux"],
      "matchMode": "any"
    }
  }
}
```

## 3. Phase 1 — Job discovery and applications

Run `npm run report` to create the daily report at `reports/daily/YYYY-MM-DD.md`.

Each vacancy includes its database Job ID, title, company, country/location, work mode, JD language, configured technical keywords found, filter status/evidence, posting and discovery dates, source, URL and JD summary. Confirmed matches and review items are included; confirmed non-matches remain in the database audit trail but are excluded from the report.

**Phase 1 does not research companies or generate interview answers.** There are no additional filters for years of experience, salary, visa, seniority, industry or architecture background.

## 4. Phase 2 — Interview preparation

After an interview invitation, create a research handoff for the selected saved vacancy:

```bash
npm run interview:prepare -- --job-id 123
```

Or select by exact company name:

```bash
npm run interview:prepare -- --company "Exact Company Name"
```

If multiple vacancies exist for that company, the command lists their Job IDs and requires a specific role selection. It reads the stored vacancy and JD, then creates `research-input.md` under `reports/interviews/<company-slug>/roles/job-<id>/`.

Next, manually invoke `.opencode/skills/company-research/SKILL.md` with that input. The skill researches the company's main business and market, analyzes the selected role, and prepares tailored interview answers such as “Why do you want to join our company?”.

Shared company research is stored once at company level. Role analysis and interview preparation are stored separately per Job ID. The CLI command only prepares the handoff; it does not itself browse the web or generate answers. Phase 2 never runs automatically during discovery.

## 5. The three filters

| Dimension | Config field | Behavior |
|---|---|---|
| Job title | `jobTitles.include` | Recognize common title variants |
| JD language | `jdLanguages.include` | Detect the actual primary JD language |
| Technical keywords | `technicalKeywords.include` | Find configured technologies in the JD |

Use `matchMode: "any"` to retain a vacancy when at least one configured keyword matches (recommended), or `all` to require every keyword. Keep unknown/incomplete cases for manual review.

## 6. Current implementation status

The daily Markdown report generator and Phase 2 job-context handoff generator are implemented. Job-board adapters, end-to-end collection and deterministic three-dimension filtering remain pending. The company-research skill is specified; automated web research, interview-answer generation and persistence of completed research are still pending.

The project never automatically submits applications or contacts employers.
